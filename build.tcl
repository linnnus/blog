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

proc format_git_timestamp ts {
    return [string map {- /} [regsub T.* $ts {}]]
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
# 	<? set x second
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

		# If we encounter an equal sign right after the `<?' we take
		# everything up until the matching `?>' as a single expression
		# to be emitted.
		set single_expression off
		if {[string index $src 0] == "="} {
			set src [string range $src 1 end]
			set single_expression on
		}

		# Find matching ?>
		if {[set i [string first ?> $src]] == -1} {
                        error "No matching ?>"
                }
		incr i -1

		# Add current command.
		if {$single_expression} { append result "emit " }
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

	foreach source_file [glob lib/*.tcl] {
		interp eval $interpreter "source [list $source_file]"
	}

	# HACK: Give it access to useful utilities.
	foreach p [list escape_html ?? normalize_git_timestamp format_git_timestamp render_markdown_file] {
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

proc get_prism_includes {content_html} {
	set result ""

	set matches [regexp -all -inline {class="language-(\w+)} $content_html]
	# "

	# Boilerplate needs to go first since deferred scripts are still loaded in order.
	if {[llength $matches] > 0} {
		append result {
			<link rel="stylesheet" href="/styles/prism.min.css">
			<script defer src="/scripts/prism.min.js"></script>
		}
	}

	set seen {}
	foreach {_ language} $matches {
		if {[lsearch -exact $seen $language] != -1} {
			continue
		}
		lappend seen $language

		global SOURCE
		set script_path "scripts/prism.${language}.min.js"
		if {[file exists $SOURCE/$script_path]} {
			append result "<script defer src=\"/$script_path\"></script>"
		}
	}

	return $result
}

proc page_html {path index} {
	global DOMAIN
	global SOURCE
	set css_path styles/[string map [list $SOURCE/ "" .md ""] $path].css
	if {[file exists $SOURCE/$css_path]} {
		set custom_css "<link rel=\"stylesheet\" href=\"/$css_path\">"
	} else {
		set custom_css ""
	}

	set content [render_markdown_file $path [dict create index $index]]

	set prism_include [get_prism_includes $content]

	return "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
		<title>[?? [extract_markdown_title $path] "Unnamed page"]</title>
		<meta property=\"og:title\" content=\"[?? [extract_markdown_title $path] "Unnamed page"]\">
		<link rel=\"stylesheet\" href=\"/styles/site.css\">
		<link rel=\"stylesheet\" href=\"/styles/normalize.css\">
		<link href=\"/atom.xml\" type=\"application/atom+xml\" rel=\"alternate\" title=\"Atom feed of all blog posts\" />
		$custom_css
		$prism_include
	</head>
	<body>
		$content
		<footer>
			<a href=\"/\">$DOMAIN</a> |
			Source available on <a href=\"https://github.com/linnnus/blog\">Github</a>
		</footer>
	</body>
</html>"
}

proc atom_xml index {
	global DOMAIN
	set proto http
	set url "$proto://$DOMAIN/atom.xml"
	set authorname "Linus"
	set first_commit [exec git log --pretty=format:%ai . | cut -d " " -f1 | tail -1]
	global SOURCE

	append result "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<feed xmlns=\"http://www.w3.org/2005/Atom\">
	<title>[extract_markdown_title $SOURCE/index.md]</title>
	<link href=\"$url\" rel=\"self\" />
	<updated>[exec date --iso=seconds]</updated>
	<author>
		<name>$authorname</name>
	</author>
	<id>tag:$DOMAIN,[normalize_git_timestamp $first_commit]:default-atom-feed</id>"

	foreach post $index {
		lassign $post path title id created updated href
		if {$created eq "draft"} continue

		set content [escape_html [render_markdown_file $path]]
		set link $proto://$DOMAIN$href
		append result "
	<entry>
		<title>$title</title>
		<content type=\"html\">$content</content>
		<link href=\"$link\" />
		<id>tag:$DOMAIN,[normalize_git_timestamp $created]:$id</id>
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
	global SOURCE
	foreach path [glob $directory/*.md] {
		set commit_times [exec git log --follow --pretty=format:%aI $path 2>/dev/null]
		set title   [?? [extract_markdown_title $path] "No title"]
		# NOTE: Filename becomes the slug, so make sure not to rename, when retitling!
		set id [file rootname [lindex [file split $path] end]]
		set created [?? [lindex $commit_times end] "draft"]
		set updated [?? [lindex $commit_times 0]   "draft"]
		set href [string map [list .md .html $SOURCE/ /] $path]
		lappend index [list $path $title $id $created $updated $href]
	}
	return [lsort -index 3 -decreasing $index]
}

set SOURCE ./src
set BUILD ./_build
set DOMAIN "ibsenware.org"

file delete -force $BUILD
file mkdir $BUILD/posts

set index [make_index $SOURCE/posts]

puts [open $BUILD/atom.xml w] [atom_xml $index]

# TODO: Find nested files like `$SOURCE/my-hobbies/index.md`.
foreach path [glob $SOURCE/*.md] {
	set out_path [string map [list .md .html $SOURCE/ $BUILD/] $path]
	set f [open $out_path w]
	puts $f [page_html $path $index]
	close $f
}

foreach path [glob $SOURCE/posts/*.md] {
	set out_path [string map [list .md .html $SOURCE/ $BUILD/] $path]
	set f [open $out_path w]
	puts $f [page_html $path $index]
	close $f
}

# TODO: Optimize assets: add hashes, minify css, compress images, etc.
file copy $SOURCE/images $BUILD/
file copy $SOURCE/documents $BUILD/
file copy $SOURCE/styles $BUILD/
file copy $SOURCE/scripts $BUILD/

# Apply for a category at girl.technology.
file mkdir $BUILD/.well-known/
set f [open $BUILD/.well-known/girl.technology w]
puts $f programmer
close $f
