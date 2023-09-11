# Archive

yes. all the posts. here.

<?
    proc format_timestamp ts {
        return [string map {- /} [regsub T.* $ts {}]]
    }

	# NOTE: Should mostly match pages/index.md
    emitln <ul>
	foreach post $param(index) {
		lassign $post path title id created updated
		set link [string map {.md .html} $path]
		emitln "<li>[format_timestamp $created]: <a href=\"[escape_html $link]\">[escape_html $title]</a></li>"
	}
    emitln </ul>
?>
