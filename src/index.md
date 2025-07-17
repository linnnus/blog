# linus' webbed site

hi there!
welcome to my personal website.
that's me, the idiot with the red shoes.
this is the dumping ground for all my useless ideas
that are too long for shitposts

; TODO: Use source-set to cut image for mobile devices
; https://developer.mozilla.org/en-US/docs/Learn/HTML/Multimedia_and_embedding/Responsive_images
![Two idiots on a tandem bike](/images/bike.webp)

## i write

it's been awhile since I last wrote longform stuff just for fun,
and the results are,,, pretty cringe if i'm being honest.
even then, i guess that's the [first step towards not sucking at it][jake]

anyways here are my <? emit [set n 3] ?> most recent posts:

<?
    emitln <ul>

	# NOTE: Should mostly match archive.md
    foreach post [lrange $param(index) 0 [expr $n - 1]] {
		lassign $post path title id created updated href
        emitln <li>
        emitln "<a href=\"[escape_html $href]\">[escape_html $title]</a>"
        emitln </li>
    }

    emitln </ul>
?>

and here are some posts i'm particularly proud of:

<?
    set favs [list longing-for-community index-redirection]

    emitln <ul>

    foreach post $param(index) {
		lassign $post path title id created updated href

        if {[lsearch -exact $favs $id] >= 0} {
            emitln <li>
            emitln "<a href=\"[escape_html $href]\">[escape_html $title]</a>"
            emitln </li>
        }
    }

    emitln </ul>
?>

you can see the full list of them over at [The Archive&trade;](/archive.html)
or read them all as a huge blob in [the amalgamation](/amalgamation.html).

[jake]: /images/jake-sucking-at-something.gif

## i write (the other kind)

; TODO: These aren't really representative of what I like to do and how cool i am.
;       I sound like some kind of web silly project guy??

most of the stuff i make is [situated software] so it doesn't really make sense to show off here

[situated software]: https://gwern.net/doc/technology/2004-03-30-shirky-situatedsoftware.html

one thing i *can* show is the [push notification api][pna].
it provides a minimal http interface for dispatching notifications to ones mobile device.
i use it to notify myself of failed cron jobs etc. on my server

[pna]: http://notifications.linus.onl/

i also co-authored the [BuffCurrency] browser extension.
it automatically convertes prices fron yuan to the users preferred currency on [buff].
i find the recursive solution pragmatically elegant
in the same way as many other effective solutions on the web.

[BuffCurrency]: https://github.com/realwakils/buffcurrency
[buff]: https://buff.163.com/

there's the [uwuifier extension][uwu]: a silly joke
which ended up requiring an unfair amount of research into
how the dom is structured and how e.g. React work under the hood.

[uwu]: https://github.com/linnnus/uwu

i've also made [hellohtml].
itslike codepen except,, much worse.

[hellohtml]: https://hellohtml.linus.onl/

## you (can) write (to me)

if you find an issue with the site feel free to [create an issue][issue].
it could be anything:
an issue with HTML accessibility,
a bad wording,
a factual mistake,
etc.

[issue]: https://github.com/linnnus/linus.onl/issues/new

i also exist in other places on the cyberweb.

; See styles/index.css for cyberspace styling.
; See images/stars.gif for the background image.
<ul class="cyberspace">
    <li class="cyberspace__item" style="top: 20%; left: 10%;"><a class="cyberspace__item__link" href="https://cohost.org/linuwus/">Cohost.org</a></li>
    <li class="cyberspace__item" style="top: 44%; left: 70%;"><a class="cyberspace__item__link" href="https://github.com/linnnus/">GitHub</a></li>
    <li class="cyberspace__item" style="top: 73%; left: 26%;"><a class="cyberspace__item__link" href="https://discord.gg/ADtHMjKdfB">the conlgang circle jerkle</a></li>
</ul>

this site is built with [`build.tcl`](https://github.com/linnnus/linus.onl).
last rebuild was at <? emit [clock format [clock seconds] -format {%H:%M on %d/%m/%Y}] ?>.
