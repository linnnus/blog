# Archive

yes. all the posts. here.

<?
	# NOTE: Should mostly match pages/index.md
	foreach post $param(index) {
		lassign $post path title id created updated
		set link [string map {.md .html} $path]
		emit "<li><a href=\"[escape_html $link]\">[escape_html $title]</a></li>\n"
	}
?>
