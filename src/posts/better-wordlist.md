# Better Danish XKCD-wordlist

In my [last post on XKCD-style passphrases][prev] I said this in my conclusion:

> Now I have a beautiful list of 8885 Danish words for password generation.
> My only snag with the wordlist is that it still contains some rather archaic words.
> If I can find some frequency data I might try to filter for the top X% most common words.

And I finally found that data!
This time I did the processing in a [Jupyter notebook][nb].
The text is in Danish
but I think the code is pretty obvious even without the commentary.

This was my first time trying out Jupyter
and I'm... not that impressed.
I really like the final artifact; rich-text comments interspersed with REPL code,
but I disliked the actual experience of doing exploratory work inside the notebook.
I kept accidentally leaving the text fields,
splitting/joining fields I didn't mean to,
scrolling the wrong box within a box within a box.
In general I found the whole experience really cramped...
idk, maybe it's just a matter of muscle memory.

I also found that I spent way more time "tinkering" with the code.
Not actually making progress,
just moving stuff around and making it look presentable.
Coupled with the added friction of the development environment,
this made for a very arduous and unenjoyable experience.
Next time I'll probably just write a shell script.

[prev]: ./xkcd-password-wordlist.html
[nb]: ../documents/danish-wordlist/wordlist.html

<div style="display:flex;flex-direction: column;align-items: center;">
    <script defer async>
        (async (me) => {
            const rawWords = await fetch("/documents/danish-wordlist/words.txt").then(r => r.text());
            const words = rawWords.split("\n");
            const random = () => { const a = new Uint32Array(1); crypto.getRandomValues(a); return a.at(0) / 4294967295; };
            const pick = arr => arr[Math.floor(random() * arr.length)];
            const upperCase = s => (s.length === 0) ? s : s[0].toUpperCase() + s.slice(1);
            const password = () => new Array(4).fill(0).map(_ => upperCase(pick(words))).join("");
            const generate$ = document.createElement("button");
            generate$.addEventListener("click", _ => {
                const result$ = document.createElement("p");
                result$.textContent = password();
                generate$.after(result$);
            });
            generate$.textContent = "Fyr mig et kodeord, gamle";
            me.after(generate$);
        })(document.currentScript);
    </script>
</div>
