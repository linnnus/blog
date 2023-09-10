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

# 
proc normalize_git_timestamp ts {
	return [regsub T.* $ts {}]
}

#
# Post processing
#

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

proc expand_bang_directives path {
	set f [open $path]
	set command ""
	while {[gets $f line] >= 0} {
		if {[regexp -line {^!! (.*)} $line -> match]} {
			append command $match\n
		} else {
			# We've just reached a normal line. If this line follows a command line, we
			# should evaluate it.
			if {[string length $command] != 0} {
				append result [exec /bin/sh -c $command]
				set command ""
			}

			append result $line
			append result \n
		}
	}

	# If the file ends on a command line...
	if {[string length $command] != 0} {
		append result [exec /bin/sh -c $command]
	}

	close $f
	return $result
}

proc render_markdown path {
	return [exec smu << [expand_bang_directives $path]]
}

#
# File generation
#

# FIXME: There *must* be a smarter way to do this...
proc index_html {foreword_path index} {
	append result "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
		<title>[?? [extract_markdown_title $foreword_path] "Unnamed blog"]</title>
		<link rel=\"stylesheet\" href=\"/assets/site.css\">
	</head>
	<body>
		[render_markdown $foreword_path]"

	append result {<ul>}
	foreach post $index {
		lassign $post path title id created updated
		set link [string map {.md .html} $path]
		append result "<li><a href=\"[escape_html $link]\">[escape_html $title]</a></li>\n"
	}
	append result {</ul>}

	append result </body></html>
	return $result
}

proc page_html path {
	return "<!DOCTYPE html>
<html>
	<head>
		<meta charset=\"UTF-8\">
		<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
		<title>[?? [extract_markdown_title $path] "Unnamed page"]</title>
		<link rel=\"stylesheet\" href=\"/assets/site.css\">
	</head>
	<body>
		[render_markdown $path]
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

		set content [escape_html [render_markdown $path]]
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
		set id [file rootname [lindex [file split $path] end]]
		set created [?? [lindex $commit_times end] "draft"]
		set updated [?? [lindex $commit_times 0]   "draft"]
		lappend index [list $path $title $id $created $updated]
	}
	return [lsort -index 2 -decreasing $index]
}

file delete -force _build
file mkdir _build/posts

set index [make_index posts]

puts [open _build/atom.xml w] [atom_xml $index]

foreach path [glob pages/*.md] {
	set out_path [string map {.md .html pages/ _build/} $path]
	set f [open $out_path w]
	if {$path eq "pages/index.md"} {
		puts $f [index_html $path $index]
	} else {
		puts $f [page_html $path]
	}
	close $f
}

foreach path [glob posts/*.md] {
	set out_path [string map {.md .html posts/ _build/posts/} $path]
	set f [open $out_path w]
	puts $f [page_html $path]
	close $f
}

file copy assets/ _build/
