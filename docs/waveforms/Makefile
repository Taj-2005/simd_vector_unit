#==============================================================================
# Waveform figures. Owner: Taj.
#
# The .svg files here are GENERATED from simulation output, not hand-drawn:
#   make -C sim vec_alu                        # produces sim/waves/tb_vec_alu.vcd
#   python docs/waveforms/make_waveform.py     # VCD -> vec_alu.svg
# then this Makefile renders PNG (slides, video) and PDF (report).
# PNG (slides, video) and PDF (vector, for the IEEE report) are generated:
#
#   make            regenerate every PNG and PDF
#   make clean      remove the generated files
#
# Needs librsvg:  brew install librsvg   /   apt-get install -y librsvg2-bin
#==============================================================================

RSVG ?= rsvg-convert

SVG := $(wildcard *.svg)
PNG := $(SVG:.svg=.png)
PDF := $(SVG:.svg=.pdf)

.PHONY: all clean
all: $(PNG) $(PDF)

# 2x so the PNG stays sharp when it fills a slide; white background because a
# transparent PNG turns into a black rectangle in most video editors.
%.png: %.svg
	$(RSVG) -f png --zoom 2 --background-color=white $< -o $@

%.pdf: %.svg
	$(RSVG) -f pdf $< -o $@

clean:
	rm -f $(PNG) $(PDF)
