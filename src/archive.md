# Archive

Here's a list of all my posts. All <? emit [llength $param(index)] ?> of them!

<?
	proc format_timestamp ts {
		return [string map {- /} [regsub T.* $ts {}]]
	}

	# NOTE: Should mostly match pages/index.md
	emitln <ul>
	foreach post $param(index) {
		lassign $post path title id created updated
		set link [string map {.md .html src/ _build/} $path]
		emitln "<li>[format_timestamp $created]: <a href=\"[escape_html $link]\">[escape_html $title]</a></li>"
	}
	emitln </ul>
?>
