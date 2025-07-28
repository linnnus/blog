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
maybe it's just a matter of muscle memory,

[prev]: ./xkcd-password-wordlist.md
[nb]: ../documents/danish-wordlist/wordlist.html
