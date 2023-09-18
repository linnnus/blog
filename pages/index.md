# linus' webbed site

welcome to my personal website. this is the dumping ground for all my useless
ideas that are too long for shitposts. it's been awhile since I last wrote
longform stuff just for fun, so we'll see how it goes. anyways here are my
<? emit [set n 3] ?> most recent posts:

<?
    emitln <ul>
	# NOTE: Should mostly match pages/archive.md
	foreach post [lrange $param(index) 0 [expr $n - 1]] {
		lassign $post path title id created updated
		set link [string map {.md .html} $path]
		emitln "<li><a href=\"[escape_html $link]\">[escape_html $title]</a></li>"
	}
    emitln </ul>
?>

you can see all of them over at [The Archive&trade;](/archive.html).

this site is built with [`build.tcl`](https://github.com/linnnus/linus.onl).
last rebuild was at <? emit [clock format [clock seconds] -format {%H:%M on %d/%m/%Y}] ?>.
