# The obligatory meta post

The current meta seems to be making personal websites. Everybody's doing it
and, if you are reading this, I am too. I hope this is the start of a
lasting, healthy online presence.

Another trend I'm noticing with these online spaces is the tendency for the
first (and often only) post to be about the site's setup and such. Since I love
talking about myself, here's a little write up about this site's current inner
workings!

## The server

First up, the hardware! This is probably the most boring part of the setup.
My site is currently running on a shitty laptop sitting in my basement. The
power cable is broken so if anyone even slightly nudges it, the computer shuts
off instantly. Not exactly Production Quality 99.99% Uptime...

![Picture of the man behind the camera giving a computer on a desk the middle finger](/images/ahmed.jpg)

It would probably have been cheaper and easier to just rent one of those
near-free VPSs somewhere but setting up this laptop was a pretty fun learning
experience. Until then, I had never tried replacing the operating system on a
computer. It was honestly pretty refreshing feeling like I was the master of
the computer and not the other way around for a change.

The server is running behind a Cloudflare proxy to provide a basic level of
security. I'll refrain from further explanations of my networking stack due to
some pretty glaring security issues which I'd rather not elaborate on...

## NixOS

An old laptop running as a server isn't *that* unusual. Much more unusual is
the choice of operating system. Rather than opting for something like Ubuntu or
Arch, I went with NixOS.

Both my ""server"" and my Macbook Pro have their configurations stored
in a single monorepo. That approach definitely has its pros and cons: it's nice
being able to share overlays and packages between the two configurations but
trying to reconcile NixOS and nix-darwin has proven to be quite a hassle. I
definitely spent waaay more time than is reasonable figuring out how to manage
such a monorepo, an issue that was not helped by Nix's absolutely bonkers
module system. Maybe I'll talk more about my ambivalent thoughts on NixOS and
the Nix ecosystem in [some other
post](/posts/my-lovehate-relationship-with-nix.html).

Once I had actually gotten NixOS configured and working, setting up the actual
server was probably something like 7 <abbr title="Lines of xode">LOC</abbr>.
Pretty simple, since running NGINX as a reverse proxy is a pretty common use
case on NixOS[^build-job].

Furthermore, if I ever decide to actually switch to a proper VPS like I
should've done from the start, I can just rebuild my NixOS config on that
machine! Magical!

[^build-job]: Actually, my setup is a little longer because I use a systemd
    service to fetch and rebuild the site every five minutes as a sort of
    poor-mans replacement for an on-push deployment. Not my finest moment...

## `linus.onl`

Finishing off my mega-scuffed config, I obviously couldn't go with a well
established <abbr title="static site generator">SSG</abbr> like Hugo or Jekyll.
Instead, I decided to take some [inspiration from Karl
B.](https://www.karl.berlin/blog.html) and write my own bespoke build script.

I decided to try using TCL for implementing this script, figuring the
language's "everything is a string" philosophy[^antirez] would make it an excellent
shell-script replacement. While that definitely was the case, the script
actually ended up not relying that much on external tools as it grew.

[^antirez]: Salvatore Antirez has written [a great
    post](http://antirez.com/articoli/tclmisunderstood.html) about the
    philosophy of TCL. I highly recommend it, both as an introduction to TCL
    and as an interesting perspective on simplicity.

While exploring the language, I learned that where TCL really shines is in its
metaprogramming capabilities. I used those to add a pretty cool preprocessing
phase to my post rendering pipeline: everything between a <code>&lt;?</code>
and a <code>?&gt;</code> is evaluated as TCL and embedded directly within the
post. The preprocessor works in three steps. First it takes the raw markup,
which looks like this:

; NOTE: <??>-block is not evaluated in here, as markdown preprocessor escapes
;       delimiters inside code-blocks.
```markdown
# My post

Here's some *markdown* with __formatting__.

The current time is <?
    set secs [clock seconds]
    set fmt [clock format $secs -format %H:%M]
    emit $fmt
?>.
```

That markup is then turned into a TCL program, which is going to generate the
final markdown, by the
[`parse`](https://github.com/linnnus/linus.onl/blob/b2f54c7478593662cc268cc5d50b5f61bc9e46c5/build.tcl#L74)
procedure.

; This is just an example of a generated program so we can use the regular code block.
```tcl
emit {# My post

Here's some *markdown* with __formatting__.

The current time is }

    set secs [clock seconds]
    set fmt [clock format $secs -format %H:%M]
    emit $fmt

emit .
```

That code is then evaluated in a child interpreter, created with [`interp
create`](https://wiki.tcl-lang.org/page/interp+create). All invocations of the
`emit` procedure are then collected by
[`collect_emissions`](https://github.com/linnnus/blog/blob/b2f54c7478593662cc268cc5d50b5f61bc9e46c5/build.tcl#L115)
into the following result:

; Since we actually want to evaluate the <??>-block we have to emulate the HTML
; output of a markdown code-block.
<pre><code class="language-markdown"># My post

Here's some *markdown* with __formatting__.

The current time is <?
    set secs [clock seconds]
    set fmt [clock format $secs -format %H:%M]
    emit $fmt
?>.
</code></pre>

This is the final markup which is passed through a markdown renderer[^cmark] to
produce the final html. This whole procedure is encapsulated in
[`render_markdown`](https://github.com/linnnus/blog/blob/b2f54c7478593662cc268cc5d50b5f61bc9e46c5/build.tcl#L47).

[^cmark]: Initially I was <abbr title="invoking an external command">shelling out</abbr> to
    [smu](https://github.com/karlb/smu/tree/bd03c5944b7146d07a88b58a2dd0d264836e3322)
    but I switched to
    [tcl-cmark](https://github.com/apnadkarni/tcl-cmark/tree/b8e203fe48f2b717365c5c58a2908019b2f36f8b)
    because smu kept messing up multi-line embedded HTML tags.

Embedded TCL is immensely powerfull. For example, the [index](/index.html) and
[archive](/archive.html) pages don't recieve any special treatment from the
build system, despite containing a list of posts. How do they include the
dynamic lists, then? The list of posts that are displayed are generated by
inline TCL:

; To avoid breakage, I have inlined it now. – Linus 2025
```markdown
# Archive

Here's a list of all my posts. All <? emit [llength $param(index)] ?> of them!

<?
	proc format_timestamp ts {
		return [string map {- /} [regsub T.* $ts {}]]
	}

	# NOTE: Should mostly match pages/index.md
	emitln <ul>
	foreach post $param(index) {
		lassign $post path title id created updated href
		emitln "<li>[format_timestamp $created]: <a href=\"[escape_html $href]\">[escape_html $title]</a></li>"
	}
	emitln </ul>
?>
```

And *that code sample was generated inline too!!* The code above is
guaranteed to always be 100% accurate, because it just reads the post source
straight from the file system.[^breakage] How cool is that!?.

[^breakage]: That *does* also mean that if the above sample is totally
    nonsensical, it's because I changed the implementation of the archive page
    and forgot to update this post.

I quite like this approach of writing a thinly veiled program to *generate* the
final HTML. In the future I'd like to see if I can entirely get rid of the
markdown renderer.

P.S. Here's a listing of the site's source directory. Not for any particular
reason other than that I spent 20 minutes figuring out how to get the
`<details>` element to work.

; `<details>` start HTML blocks that end on the next blank line. As such, they
; are a bit annoying to use with `<pre>` elements that contain blank lines.
; Here, I opted to just get rid of the blank lines.
<details>
    <summary>Directory listing</summary>
    <pre><code>linus.onl/
├── assets
│   ├── images
│   │   └── ahmed.jpg
│   └── styles
│       ├── normalize.css
│       └── site.css
├── pages
│   ├── about.md
│   ├── archive.md
│   └── index.md
├── posts
│   ├── first-post.md
│   ├── my-lovehate-relationship-with-nix.md
│   ├── second-post.md
│   ├── the-obigatory-metapost.md
│   └── third-post.md
├── Makefile
├── README.md
├── build.tcl
├── local.vim
└── shell.nix
</code></pre></details>

## Conclusion

All in all, this isn't the most exotic setup, nor the most minimal, but it's
mine and I love it. Particularly the last bit about the build system. I love
stuff that eat's its own tail like that.

I hope this post was informative, or that you at least found my scuffed setup
entertaining :)
