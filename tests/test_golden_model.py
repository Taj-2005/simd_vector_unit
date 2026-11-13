"""Tests for the SIMD golden model.

The golden model is what `tb/tb_system.v` trusts, so a wrong model turns into a
day of debugging correct RTL. These tests pin the three conventions the RTL and
the model have to agree on: lane packing order, wrapping arithmetic, and narrow
signed compares.

    pytest tests/ -v
"""

import pytest
from golden_model import (
    ALU_ADD,
    ALU_AND,
    ALU_CMPEQ,
    ALU_CMPLT,
    ALU_OR,
    ALU_SHL,
    ALU_SUB,
    LANE_MASK,
    LANE_W,
    LANES,
    OP_NAMES,
    VEC_W,
    from_hex,
    lane_op,
    pack,
    to_hex,
    to_signed,
    to_unsigned,
    unpack,
    vec_op,
)


class TestGeometry:
    def test_vector_is_four_lanes_of_thirty_two_bits(self):
        assert LANES == 4
        assert LANE_W == 32
        assert VEC_W == 128

    def test_lane_zero_occupies_the_low_bits(self):
        # The generate loop in vec_alu.v wires lane i to bits [i*32 +: 32]. If
        # this test fails, the packing convention changed and every committed
        # expected_*.hex file is now wrong.
        assert pack([1, 0, 0, 0]) == 1
        assert pack([0, 1, 0, 0]) == 1 << 32
        assert pack([0, 0, 0, 1]) == 1 << 96

    def test_pack_and_unpack_round_trip(self):
        lanes = [0xDEADBEEF, 0x00000000, 0xFFFFFFFF, 0x12345678]
        assert unpack(pack(lanes)) == lanes

    def test_pack_masks_oversized_values(self):
        assert unpack(pack([1 << 32, 0, 0, 0]))[0] == 0


class TestSignedness:
    @pytest.mark.parametrize(
        ("pattern", "expected"),
        [
            (0x00000000, 0),
            (0x00000001, 1),
            (0x7FFFFFFF, 2**31 - 1),
            (0x80000000, -(2**31)),
            (0xFFFFFFFF, -1),
        ],
    )
    def test_to_signed(self, pattern, expected):
        assert to_signed(pattern) == expected

    def test_to_unsigned_is_the_inverse(self):
        for pattern in (0x00000000, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF):
            assert to_unsigned(to_signed(pattern)) == pattern


class TestLaneOps:
    def test_add(self):
        assert lane_op(ALU_ADD, 7, 5) == 12

    def test_add_wraps_without_a_carry_flag(self):
        # The hardware has no carry-out, so this must wrap rather than widen.
        assert lane_op(ALU_ADD, 0xFFFFFFFF, 1) == 0
        assert lane_op(ALU_ADD, 0xFFFFFFFF, 0xFFFFFFFF) == 0xFFFFFFFE

    def test_sub(self):
        assert lane_op(ALU_SUB, 7, 5) == 2

    def test_sub_borrows_into_twos_complement(self):
        assert lane_op(ALU_SUB, 5, 7) == 0xFFFFFFFE
        assert to_signed(lane_op(ALU_SUB, 5, 7)) == -2

    def test_and_or(self):
        assert lane_op(ALU_AND, 0xF0F0F0F0, 0x0FF00FF0) == 0x00F000F0
        assert lane_op(ALU_OR, 0xF0F0F0F0, 0x0FF00FF0) == 0xFFF0FFF0

    def test_compares_are_narrow(self):
        # 1 or 0 in bit 0, zeros above - not an all-ones mask. tb_lane_alu.v
        # asserts the same thing.
        assert lane_op(ALU_CMPEQ, 4, 4) == 1
        assert lane_op(ALU_CMPEQ, 4, 5) == 0
        assert lane_op(ALU_CMPEQ, 0xFFFFFFFF, 0xFFFFFFFF) == 1

    def test_cmplt_is_signed(self):
        # The one case an unsigned comparator gets wrong: -1 < 1.
        assert lane_op(ALU_CMPLT, 0xFFFFFFFF, 1) == 1
        assert lane_op(ALU_CMPLT, 1, 0xFFFFFFFF) == 0
        assert lane_op(ALU_CMPLT, 0x80000000, 0x7FFFFFFF) == 1

    def test_cmplt_is_strict(self):
        assert lane_op(ALU_CMPLT, 5, 5) == 0

    def test_shl_uses_only_five_shift_bits(self):
        assert lane_op(ALU_SHL, 1, 4) == 16
        assert lane_op(ALU_SHL, 1, 32) == 1  # 32 & 0x1F == 0
        assert lane_op(ALU_SHL, 0xFFFFFFFF, 31) == 0x80000000

    def test_undefined_op_code_is_an_error_not_a_zero(self):
        with pytest.raises(ValueError):
            lane_op(0b111, 1, 2)


class TestVecOp:
    def test_lanes_are_independent(self):
        a = [10, 20, 30, 40]
        b = [1, 2, 3, 4]
        assert vec_op(ALU_ADD, a, b) == [11, 22, 33, 44]

    def test_one_lane_wrapping_does_not_touch_its_neighbours(self):
        a = [0xFFFFFFFF, 5, 0xFFFFFFFF, 7]
        b = [1, 5, 1, 7]
        assert vec_op(ALU_ADD, a, b) == [0, 10, 0, 14]

    def test_compares_can_differ_per_lane(self):
        # The pattern gen_vectors.py crafts for the logic benchmark.
        a = [100, 100, 100, 0xFFFFFFFF]
        b = [100, 99, 101, 1]
        assert vec_op(ALU_CMPEQ, a, b) == [1, 0, 0, 0]
        assert vec_op(ALU_CMPLT, a, b) == [0, 0, 1, 1]

    def test_wrong_lane_count_is_rejected(self):
        with pytest.raises(ValueError):
            vec_op(ALU_ADD, [1, 2, 3], [1, 2, 3])

    def test_every_named_op_runs_across_lanes(self):
        a = [1, 2, 3, 4]
        b = [4, 3, 2, 1]
        for op in OP_NAMES.values():
            result = vec_op(op, a, b)
            assert len(result) == LANES
            assert all(0 <= value <= LANE_MASK for value in result)


class TestHexFormat:
    def test_vector_is_thirty_two_hex_digits(self):
        # $readmemh fills from the right, so a short line silently zero-pads the
        # wrong end of the word. Fixed width is not cosmetic.
        assert len(to_hex(0)) == 32
        assert to_hex(1) == "0" * 31 + "1"
        assert to_hex((1 << 128) - 1) == "f" * 32

    def test_round_trip(self):
        word = pack([0xDEADBEEF, 0x12345678, 0, 0xFFFFFFFF])
        assert from_hex(to_hex(word)) == word

    def test_comments_and_underscores_are_tolerated(self):
        assert from_hex("00ff  // lane note") == 0x00FF
        assert from_hex("0000_00ff") == 0x00FF

    def test_empty_line_is_an_error(self):
        with pytest.raises(ValueError):
            from_hex("   // only a comment")


class TestVectorFilesMatchTheModel:
    """The committed vectors must be what the current model produces.

    Regenerating with a different seed and forgetting to commit the expectation
    is the failure this catches - the RTL would then be blamed for a mismatch it
    did not cause.
    """

    def _read(self, name):
        from pathlib import Path

        path = Path(__file__).resolve().parent.parent / "sim" / "vectors" / name
        if not path.exists():
            pytest.skip(f"{name} not generated yet; run make -C sim vectors")
        return [
            from_hex(line) for line in path.read_text().splitlines() if line.strip()[:2] != "//"
        ]

    def test_expected_add_is_the_sum_of_the_inputs(self):
        a = self._read("a.hex")
        b = self._read("b.hex")
        expected = self._read("expected_add.hex")
        assert len(a) == len(b) == len(expected) == 4
        for i in range(4):
            assert vec_op(ALU_ADD, unpack(a[i]), unpack(b[i])) == unpack(expected[i])

    def test_dmem_init_holds_a_then_b(self):
        a = self._read("a.hex")
        b = self._read("b.hex")
        image = self._read("dmem_init.hex")
        assert image == a + b

    def test_logic_expectations_cover_more_than_one_answer_per_op(self):
        # A compare whose lanes all agree would pass with the comparator
        # deleted, so assert the crafted pair really does vary.
        logic = self._read("expected_logic.hex")
        cmpeq_lanes = unpack(logic[2])
        cmplt_lanes = unpack(logic[3])
        assert set(cmpeq_lanes) == {0, 1}
        assert set(cmplt_lanes) == {0, 1}
