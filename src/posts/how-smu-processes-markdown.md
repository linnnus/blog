# How smu parses Markdown

A while ago, someone asked about parsing Markdown on Cohost.
[Their original post][question] and my answer is still online
but since Cohost has gone the way of the Dodo
I wanted to repost it here on my blog:

I'd like to explain how the [Suckless Project's markdown parser (`smu`)][smu] works
because it works a little differently to how most other parsers I've seen work.
It's not necessarily the cleanest approach but I still think the way
`smu`  works is pretty fun, if not exactly elegant.
I'll walk through the code below.
Be warned though, C pointer juggling up ahead!

The heart of `smu` is the function `process` which takes in a Markdown string
(delimited by the `start` and `end` pointers) and writes the corresponding HTML
to standard output:

```c
void process(const char *begin, const char *end, int newblock) {
    const char *p;
    int affected;
    unsigned int i;

    for (p = begin; p < end;) {
        /* snip */

        for (i = 0; i < LENGTH(parsers); i++)
            if ((affected = parsers[i](p, end, newblock)))
                break;
        if (affected)
            p += abs(affected);
        else
            fputc(*p++, stdout);

        /* snip */

        if (p[0] == '\n' && p + 1 != end && p[1] == '\n')
            newblock = 1;
        else
            newblock = affected < 0;
    }
}
```

The interesting part is the inner loop:
every parser gets a shot at parsing the input and returns the number of characters it consumed,
otherwise (i.e. if no parser returns non-zero) the character is just echoed verbatim to standard output:

```c
for (i = 0; i < LENGTH(parsers); i++)
    if ((affected = parsers[i](p, end, newblock)))
        break;
if (affected)
    p += abs(affected);
else
    fputc(*p++, stdout);
```

For example, here is a function `dobold`
which handles bolded text
(like "this" in the input ``like **this** text``):

```c
int dobold(const char *begin, const char *end, bool newblock) {
    const char *const MARK = "**";
    const size_t MARK_LEN = 2;

    // Input could never be bold if it doesn't have room for opening/closing markers.
    if (end - begin < MARK_LEN * 2) {
        return 0;
    }

    // Eat opening **
    if (strncmp(begin, MARK, MARK_LEN) != 0) {
        return 0;
    }
    const char *start = begin + MARK_LEN;

    // Find closing **, ignoring escaped \**
    const char *stop = start;
    do {
        stop = strnstr(stop + 1, MARK, end - (stop + 1));
    } while (stop != NULL && stop[-1] == '\\');
    if (stop == NULL) {
        return 0; // This wasn't bold anyways...
    }

    fputs("<strong>", stdout);
    process(start, stop, false); // Handle nested markup
    fputs("</strong>", stdout);

    return stop - start + 2 * MARK_LEN;
}
```

Notice how can just `return 0` to indicate
that `dobold` does not handle whatever the current input string is.
This provides a sort of "infinite lookahead"
which is super useful
when parsing Markdown,
because it has a very messy grammar
that doesn't lend itself to easily parsing with limited lookahead.

An example of this "infinite lookahead" can be seen
when `stop == NULL` after the loop,
meaning we didn't find a(n un-escaped) closing marker.
At this point, a recursive descent parser,
which is normally my go-to tool for parsing problems,
would have consumed a lot of tokens which now couldn't be matched by subsequent rules.
Instead of doing some complicated backtracking,
`dobold` can simply `return 0`.
I see this as a major strength of `smu`'s approach.

Another strength is flexibility.
`process` doesn't impose a big framework on any of the parsing functions
it invokes.
Instead, the contract is pretty simple:

* The input is delimited by `begin` (inclusive) and `end` (exclusive),
* HTML should be written to `stdout`,
* Return the number of characters consumed.
* Negate the return-value if this was a block-level element (Markdown-specific).

These constraints give parsers a lot of wiggle-room
as compared to (e.g.) parser combinators or recursive descent.
For example, `doparagraph` just straight up uses a regular expression and global state because doing so is easier.

```c
int doparagraph(const char *begin, const char *end, int newblock) {
    const char *p;
    regmatch_t match;

    // Paragraph is a block-level structure, though there are some exceptions, which is why in_paragraph is needed.
    if (!newblock)
        return 0;

    if (regexec(&p_end_regex, begin + 1, 1, &match, 0)) {
        p = end;
    } else {
        p = begin + 1 + match.rm_so;
    }

    fputs("<p>", stdout);
    in_paragraph = 1;
    process(begin, p, 0);
    end_paragraph(); // Prints </p> if another block-level element hasn't already implicitly closed the paragraph.

    return -(p - begin);
}
```

I used the same approach as `smu` for my parser for [Wiki Creole][wiki-creole].
I've found that if you can keep the pointer-juggling straight
(which may not even be a problem in languages with better string handling than C)
this approach makes for a very fun and approachable way to structure a parser!

P.S. `smu` has a few pretty nasty constructs, like `end_paragraph()`,
which are necessary because Markdown is so messy.
If possible, I think it pays of hugely to be a little more strict in the design of a Markdown language.
The Wiki Creole specification is pretty loose,
so when I made my parser
I simply dictated that there had to be at least one blank line between all block-level elements,
thus getting rid of the need for `end_paragraph()`!

[question]: https://web.archive.org/web/20250107034356/https://cohost.org/wffl/post/6136974-i-wonder-how-you-par
[smu]: https://github.com/Gottox/smu
[wiki-creole]: https://wikicreole.org
