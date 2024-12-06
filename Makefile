_build: $(wildcard posts/* assets/* pages/*) build.tcl
	tclsh build.tcl

all: _build

serve:
	python3 -m http.server --directory _build/

watch:
	fswatch --recursive --directories . --exclude _build | while read; do \
		$(MAKE) _build; \
	done

dev: | _build
	trap 'printf "\rGot SIGINT. Killing children..." ; kill $$(jobs -p)' SIGINT; \
	$(MAKE) watch & \
	$(MAKE) serve & \
	wait; \
	exit 0

clean:
	rm -rf _build/

.PHONY: clean all serve watch dev
.DEFAULT_GOAL: all
