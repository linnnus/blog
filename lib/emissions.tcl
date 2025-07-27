# TODO: Better naming that indicates what is safe vs. unsafe.

# This output variable is extracted from the interpreter after the script has finished.
global collect_emissions_result
set collect_emissions_result {}

proc emit txt {
	global collect_emissions_result
	append collect_emissions_result $txt
}

proc emitln {{txt ""}} { emit $txt\n }
