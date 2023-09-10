all:
	tclsh build.tcl

serve:
	python3 -m http.server --directory _build/

clean:
	rm -rf _build/

.PHONY: clean all serve
