; Little helper which I can inspect to see if the webhook fired correctly.
<!-- Rendered: <?= [clock format [clock seconds] -timezone UTC -format "%Y-%m-%dT%H:%M:%SZ"] ?> -->
<!-- Commit: <?= [exec git rev-parse HEAD] ?> -->
<!-- Dirty: <?= [exec /bin/sh -c {git diff-index --quiet HEAD ; echo $?}] ?> -->

# Welcome!

My name's Linus and you've found my little corner of the internet.

In meatspace, I am currently enjoying a gap-year
--- doing some traveling and trying different jobs
before studying computer science in 2026.
This blog will probably be mostly technical, though.

So about the technical stuff:
Right now I'm really into PL-dev and also trying to learn React
without entirely losing faith in the web as a platform.
In 2022 I caught the Nix flu.
It's a terrible disease to have;
the Nix user experience is horrible
("infinite recursion encountered" is the modern day [`?` error][ed])
but there's no way in hell I'm ever going back to impure software.
This must be what it feels like to be one of those enlightened Rust types <? winky ?>

[ed]: https://en.wikipedia.org/wiki/Ed_(software)#Cultural_references

---

<?
    proc emit_toc {index} {
        emitln {<div class="toc">}

        foreach post $index {
            lassign $post path title id created updated href
            emit {<a class="toc__row" href="}
            emit [escape_html $href]
            emit {">}
            emitln

            emit {<span class="toc__title">}
            emit [escape_html $title]
            emit </span>
            emitln

            emitln {<div class="toc__separator"></div>}

            emit {<div class="toc__date">}
            emit [escape_html [format_git_timestamp $created]]
            emit </div>
            emitln

            emitln </a>
        }

        emitln </div>
    }

    emit_toc $param(index)
?>

---

I love to chat, so feel free to reach out!
You can find my contact details over at my [contact page](/contact.html).
I think the web would be a much more fun/social place
if people were less hesitant in reaching out <? smiley_nose ?>
