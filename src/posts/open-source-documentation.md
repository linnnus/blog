# Documenting open source code

Today a friend of mine mentioned an issue they'd had with [Radarr][radarr],
the movie organizer for torrent users.
Since it's an open source project,
I figured I could just fix the issue myself --
easy peasy.
But man, [the code for radarr][radarr-code] is *obtuse*...
Everything is encapsulated in a subclass of an abstract base class implementing an interface for a service (sic)
and there's not a single comment to be found.

Documentation of open source projects is yet another instance of [the 80/20 rule][pareto]:
relatively little documentation goes a long way in helping new contributors find their footing in a project.
It can be as simple as writing a couple of lines at the top of every file describing what the module does,
or throwing a couple of `readme.txt`s in the folder for each major component.

[Wren][wren-lang] is of course the ideal.
Its source code reads more like a book than a program,
though such a comparison is hardly fair;
Wren is as much a tutorial as it is an actual live programming language[^wren-ratio].
Obviously, not every project can dedicate that much time to documentation.

[^wren-ratio]: As of `c2a75f1e` there are 3811 semicolons and 2665 comment lines.
That's a ratio of approximately 0.70 comments for every statement!

The [Neovim][neovim] project strikes a much more reasonable balance.
Let's take a look at a [`src/nvim/undo.c`][neovim-undo],
it contains some rather tricky code for managing the editor's multi-level undo tree.
The reason I know this isn't because I'm some kind of Neovim expert,
I just read comment at the top of the file!

```c
// undo.c: multi level undo facility
```

That comment is followed by [a longer comment][neovim-comment] explaining
how the main data structure of the module works.
I think that's a much better use of the space at the top of the file than the ever-present license comment.

If the Radarr maintainers had been better about documenting their project,
I would've already finished making my change.
Instead, I'm stuck doing detective work trying to figure out what part of the code I'm even looking for.
I do of course understand that writing documentation takes time
but I think it is well worth it
because it supercharges one-time contributors.

[radarr]: https://radarr.video/
[radarr-code]: https://github.com/Radarr/Radarr/
[pareto]: https://en.wikipedia.org/wiki/Pareto_principle#Computing
[wren-lang]: https://wren.io/
[neovim]: https://github.com/neovim/neovim
[neovim-undo]: https://github.com/neovim/neovim/blob/08986bb5972d5289b5ae581eee20c56387cf5ddd/src/nvim/undo.c
[neovim-comment]: https://github.com/neovim/neovim/blob/08986bb5972d5289b5ae581eee20c56387cf5ddd/src/nvim/undo.c#L3-L65
