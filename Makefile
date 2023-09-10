_build: $(wildcard posts/* assets/* pages/*) build.tcl
	tclsh build.tcl

all: _build

serve:
	python3 -m http.server --directory _build/

clean:
	rm -rf _build/

.PHONY: clean all serve
.DEFAULT_GOAL: all
