"""Put golden/ on the import path so the tests can import the model directly.

The golden model is not a package: `tb/tb_system.v` and `sim/Makefile` run
`golden/gen_vectors.py` as a plain script, and keeping it importable both ways
avoids a `python -m` wrapper nobody would remember to use.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "golden"))
