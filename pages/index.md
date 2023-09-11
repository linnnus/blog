# linus' webbed site

welcome to my personal website. this is the dumping ground for all my useless
ideas that are too long for shitposts. here are some of my recent posts:

<?
    emitln <ul>
	# NOTE: Should mostly match pages/archive.md
	foreach post [lrange $param(index) 0 2] {
		lassign $post path title id created updated
		set link [string map {.md .html} $path]
		emitln "<li><a href=\"[escape_html $link]\">[escape_html $title]</a></li>"
	}
    emitln </ul>
?>

you can see all of them over at [The Archive™️](/archive.html).
