# Amalgamation

This page contains all posts amalgamated into a single page [SQL-style][sql-amalgamation].
You can use this if you want to [doomscroll] all my posts, I guess.
For me, it was a nice way to learn about [how to improve load times using `content-visibility`][content-visibility].

[sql-amalgamation]: https://www.sqlite.org/amalgamation.html
[doomscroll]: https://dictionary.cambridge.org/dictionary/english/doomscrolling
[content-visibility]: https://youtu.be/FFA-v-CIxJQ

<?
	foreach post $param(index) {
		lassign $post path title id created updated
		emitln {<article class="post">}
		emitln [render_markdown_file $path $param(__raw_env)]
		emitln {</article>}
	}
?>

That's it! There are no more posts...
