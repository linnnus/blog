all:
	tclsh build.tcl

serve:
	python3 -m http.server --directory _build/

clean:
	rm -rf build/

.PHONY: clean all serve
