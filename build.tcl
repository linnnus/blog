package require Tcl 8.5
package require cmark 1.0

#
# Utilities
#

proc ?? {value fallback} {
	if {$value != ""} {
		return $value
	} else {
		return $fallback
	}
}

proc extract_markdown_title path {
	set f [open $path]
	while {[gets $f line] >= 0} {
		if {[regexp -line {^# (.*)} $line -> title]} {
			close $f
			return $title
		}
	}
	close $f
}

proc escape_html raw {
	set html_entities {
		"&" "&amp;"
		"<" "&lt;"
		">" "&gt;"
		"\"" "&quot;"
		"'" "&#39;"
	}

	return [string map $html_entities $raw]
}

proc normalize_git_timestamp ts {
	return [regsub T.* $ts {}]
}

#
# Post rendering
#

proc render_markdown_file {path {env {}}} {
	set fd [open $path r]
	set markdown_source [read $fd]
	close $fd

	return [render_markdown $markdown_source $env]
}

proc render_markdown {markdown_source {env {}}} {
	set result $markdown_source

	# Remove comment lines. These are replaced with an empty line and as
	# such can be used to split block-level elements like paragraphs.
	regsub -line -all {^; .*$} $result {} result

	set result [::cmark::render -footnotes -smart -unsafe -strikethrough $result]

	# Note that we run the expansion of TCL after markdown has been
	# expanded. The delimiters <? and ?> denote a HTML-block per the
	# CommonMark specification and is thus left alone by any correct
	# markown implementation.
	#
	# This also means that TCL blocks inside markdown code-blocks will be
	# escaped, i.e. < and > are transformed to &lt; and &gt; which are not
	# recognized by the parse function. This is good.
	#
	# See: https://spec.commonmark.org/0.30/#html-blocks
	set result [expand $result $env]

	return $result
}

# Turn `source' into some code which invokes the `emit' procedure to generate
# output. It turns...
#
# 	This is the first line.
# 	<? x second
# 	emit {this is the $x line.\n} ?>
# 	This is the third line.
#
# ...into...
#
# 	emit {This is the first line.\n}
# 	set x second 
# 	emit {this is the $x line.\n} 
# 	emit {This is the third line.\n}
#
proc parse src {
	set result {}
	while {[set i [string first <? $src]] != -1} {
		incr i -1

		# Add invocation of `emit' for text until current command.
		append result "emit [list [string range $src 0 $i]]\n"
		set src [string range $src [expr {$i + 3}] end]

		# Find matching ?>
		if {[set i [string first ?> $src]] == -1} {
                        error "No matching ?>"
                }
		incr i -1

		# Add current command.
		append result "[string range $src 0 $i]\n"
                set src [string range $src [expr {$i + 3}] end]
	}

	# Add trailing plaintext.
	if {$src != {}} {
		append result "emit [list $src]\n"
	}

	return $result
}

# Evaluates `code' and collects invocations of `emit' into the returned string.
# It turns...
#
# 	emit {This is the first line.\n}
# 	set x second
# 	emit {this is the $x line.\n}
# 	emit {This is the third line.\n}
#
# ...into...
#
# 	This is the first line.
# 	this is the second line.
# 	This is the third line.
#
proc collect_emissions {code {env {}}} {
	set interpreter [interp create]

	# Set up `emit' and `emitln' so child interpreter can append to output
	# variable. The output variable is extracted from the interpreter after
	# the script has finished.
	# TODO: Better naming that indicates what is safe vs. unsafe.
	interp eval $interpreter {
		global collect_emissions_result
		set collect_emissions_result {}

		proc emit txt {
			global collect_emissions_result
			append collect_emissions_result $txt
		}

		proc emitln txt { emit $txt\n }
	}

	# HACK: Give it access to useful utilities.
	foreach p [list escape_html ?? normalize_git_timestamp render_markdown_file] {
		interp alias $interpreter $p {} $p
	}

	# Pass a _copy_ of `env' to child interpreter. These are called "parameters".
	dict for {key value} $env {
		interp eval $interpreter [list set "param($key)" $value]
	}
	interp eval $interpreter [list set param(__raw_env) $env]

	# Evaluate code which calls emit.
	interp eval $interpreter $code

	# Extract the final HTML.
	set result [interp eval $interpreter set collect_emissions_result]

	interp delete $interpreter
	return $result
}

# Composes `parse' and `collect_emissions'.
proc expand {src {env {}}} {
	set code [parse $src]
	set txt [collect_emissions $code $env]
	return $txt
}

#
# File generation
#

proc page_html {path index} {
	set css_path assets/styles/[string map {pages/ "" .md ""} $path].css
	if {[file exists $css_path]} {
		set custom_css "<link rel=\"stylesheet\" href=\"/$css_path\">"
	} else {
		set custom_css ""
	}

	return "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
		<title>[?? [extract_markdown_title $path] "Unnamed page"]</title>
		<link rel=\"stylesheet\" href=\"/assets/styles/site.css\">
		<link rel=\"stylesheet\" href=\"/assets/styles/normalize.css\">
		<script type=\"module\" src=\"/assets/scripts/favicon-anchors.js\"></script>
		$custom_css
	</head>
	<body>
		<main>[render_markdown_file $path [dict create index $index]]</main>
		<footer>
			<a href=\"/\">Go to index</a> |
			Source available on <a href=\"https://github.com/linnnus/linus.onl\">Github</a> |
			Made with &#x1F468;&#x200D;&#x1F9AF; by Linus
		</footer>
	</body>
</html>"
}

proc atom_xml index {
	set host "linus.onl"
	set proto http
	set url "$proto://$host/atom.xml"
	set authorname "Linus"
	set first_commit [exec git log --pretty=format:%ai . | cut -d " " -f1 | tail -1]

	append result "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<feed xmlns=\"http://www.w3.org/2005/Atom\">
	<title>[extract_markdown_title pages/index.md]</title>
	<link href=\"$url\" rel=\"self\" />
	<updated>[exec date --iso=seconds]</updated>
	<author>
		<name>$authorname</name>
	</author>
	<id>tag:$host,[normalize_git_timestamp $first_commit]:default-atom-feed</id>"

	foreach post $index {
		lassign $post path title id created updated
		if {$created eq "draft"} continue

		set content [escape_html [render_markdown_file $path]]
		set link $proto://$host/[string map {.md .html} $path]
		append result "
	<entry>
		<title>$title</title>
		<content type=\"html\">$content</content>
		<link href=\"$link\" />
		<id>tag:$host,[normalize_git_timestamp $created]:$id</id>
		<published>$created</published>
		<updated>$updated</updated>
	</entry>"
	}

	append result </feed>
	return $result
}

#
# Driver code
#

proc make_index directory {
	foreach path [glob $directory/*.md] {
		set commit_times [exec git log --pretty=format:%aI $path 2>/dev/null]
		set title   [?? [extract_markdown_title $path] "No title"]
		# NOTE: Filename becomes the slug, so make sure not to rename, when retitling!
		set id [file rootname [lindex [file split $path] end]]
		set created [?? [lindex $commit_times end] "draft"]
		set updated [?? [lindex $commit_times 0]   "draft"]
		lappend index [list $path $title $id $created $updated]
	}
	return [lsort -index 3 -decreasing $index]
}

file delete -force _build
file mkdir _build/posts

set index [make_index posts]

puts [open _build/atom.xml w] [atom_xml $index]

foreach path [glob pages/*.md] {
	set out_path [string map {.md .html pages/ _build/} $path]
	set f [open $out_path w]
	puts $f [page_html $path $index]
	close $f
}

foreach path [glob posts/*.md] {
	set out_path [string map {.md .html posts/ _build/posts/} $path]
	set f [open $out_path w]
	puts $f [page_html $path $index]
	close $f
}

# TODO: Optimize assets: add hashes, minify css, compress images, etc.
file copy assets/ _build/

# Apply for a category at girl.technology.
file mkdir _build/.well-known
set f [open _build/.well-known/girl.technology w]
puts $f programmer
close $f
