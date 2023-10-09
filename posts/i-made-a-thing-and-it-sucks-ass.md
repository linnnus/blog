# I made a thing and it sucks ass

It is not a big thing. It's just a little utility that shows a hover preview
when the mouse hovers a link. I think it's kind of useful for checking where a
link goes when I see text like "You can read more about that
[here](https://www.youtube.com/watch?v=dQw4w9WgXcQ)".

![A screenshot of a blog post. The mouse hovers a link. A popup above the link shows the title and description of the page](/assets/images/hover-screenshot.png)

Anyways, the thing is, it didn't take me very long to make this. An hour or two
including setting up the user script manager and whatnot. However, the issue
is: I just. keep. finding. edge cases. Here's a couple of examples:

* Most sites don't actually implement the OpenGraph protocol so the popups are
  kind of useless unless I also implement metadata extraction myself. For now I
  just extract a `<title>` if one is present but realistically I also need to
  generate a description/summary.
* Popups tend to 'leak' on SPAs because they simply remove the `<a>` tag from
  the DOM so  the `mouseleave` event doesn't fire. That's pretty easy to
  handle; just treat element destruction like `mouseleave`.
* I have to use a proxy to get around CORS issues, but fetch doesn't support
  actually using proxies and the proxy I use doesn't handle redirects, so if a
  link leads to a redirect, I just get a generic `NetworkError`.

Each of these issues on their own isn't the end of the world, but the
cumulative time spent fixing bugs just isn't worth it for a small, semi-useful
utility.

This whole ordeal reminded me a lot of my [uwuifier
extension](https://github.com/linnnus/uwu/commits/master); a silly idea which
ended up taking multiple iterations over the span of two years, APIs spanning
the entire history of the DOM, and a way too intimate understanding of the DOM
tree's structure. And it's still not finished! I stuck with that project,
because I thought it was funny and some of my friends were using it, but I just
don't have that motivation this time.

The tl;dr is that I made a kind of useful utility, but to implement it fully
would require a disproportionate amount of work. So much work that I don't
think I'll finish the thing. And that's why I hate making stuff for the web.
