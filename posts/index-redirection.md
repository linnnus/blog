# Link rot and the innevitable heat death of the internet

## Introduction

Yesterday I was reading the slides for Maciej Ceglowski's talk on [The Website Obesity Crisis].
It's a really good talk.
I highly recommend giving it a read
(or [a watch]).
You might be a bit skeptical since it was written in 2015,
but I think it is still highly relevant,
even to HTML kiddies[^html-kiddies] such as myself.
Much like all good dystopian works,
it identified the beginnings of a trend which has now become such a huge issue
that the original work seems almost prophetic.

[The Website Obesity Crisis]: https://idlewords.com/talks/website_obesity.htm
[a watch]: https://webdirections.org/blog/the-website-obesity-crisis
[^html-kiddies]: For lack of a better term I'm just going to reuse [script kiddies](https://en.wikipedia.org/wiki/Script_kiddie).

Anyway, in one of the slides he talks about an experiment by some Adam Drake guy.

> Adam Drake wrote an engaging blog post about [analyzing 2 million chess games].
> Rather than using a Hadoop cluster, he just piped together some Unix utilities on a laptop,
> and got a 235-fold performance improvement over the 'Big Data' approach.

[analyzing 2 million chess games]: http://aadrake.com/command-line-tools-can-be-235x-faster-than-your-hadoop-cluster.html

It seemed pretty interesting, so I clicked the link and... nothing?
The link just took me to his homepage[^douchebag-techbro].
After a bit of detective work I figured out
that the server was just redirecting me to the homepage instead of showing a 404.
Specifically, the Curl output below shows
that any request made to his old domain (`aadrake.com`) is met with a [301 "permanently moved"]
pointing to the index page of his new domain (`adamdrake.com`),
completely disregarding the actual resource being requested.

[301 "permanently moved"]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/301
[^douchebag-techbro]: A home that included the phrase
"While I specialize in executive advising on leadership and process, I can also dive into deep technical problems with Data Science",
a sentence so douchebag-techbro-y it made me reconsider whether tech was really the industry for me.

<details>
    <summary>Curl output</summary>
    <p>Emphasis mine.</p>
    <pre><code>$ curl -v http://aadrake.com/command-line-tools-can-be-235x-faster-than-your-hadoop-cluster.html
*   Trying 192.64.119.137:80...
* Connected to aadrake.com (192.64.119.137) port 80 (#0)
&gt; GET <b>/command-line-tools-can-be-235x-faster-than-your-hadoop-cluster.html</b> HTTP/1.1
&gt; Host: aadrake.com
&gt; User-Agent: curl/8.1.1
&gt; Accept: */*
&gt;
&lt; HTTP/1.1 <b>301 Moved Permanently</b>
&lt; Date: Sun, 22 Oct 2023 21:12:20 GMT
&lt; Content-Type: text/html; charset=utf-8
&lt; Content-Length: 56
&lt; Connection: keep-alive
&lt; Location: <b>https://adamdrake.com</b>
&lt; X-Served-By: Namecheap URL Forward
&lt; Server: namecheap-nginx
&lt;
&lt;a href='https://adamdrake.com'&gt;Moved Permanently&lt;/a&gt;.
* Connection #0 to host aadrake.com left intact</code></pre>
</details>

He is not the only one doing this.
I've encountered multiple websites with this 404-is-index strategy and I hate it.
It's the HTTP equivalent of going "what? nah bro i never said that".
Why is your server gaslighting me?

## Link rot

Even then, it is not the end of the world.
It is just mildly annoying.
I do, however, think that it is part of the much larger issue of [link rot].
The term "link rot" refers to the tendency for hyperlinks to 'go bad' over time,
as the resources are relocated or taken offline.
It is a kind of digital entropy that is slowly engulfing much of the older/indie web.

[link rot]: https://en.wikipedia.org/wiki/Link_rot

The 404-is-index strategy is a particularly bad case of link rot.
Unlike a usual 404 which presents the reader with some kind of error page,
a 301 happens quietly.
For example many bookmark managers will quietly update references when it encounters a 301.
This means that your bookmarks just disappear because they've been 'moved' to the website's index page.

Maciej Ceglowski's talk is yet another example.
His link to `aadrake.com` was quietly broken
and with that another edge in the huge directed graph
that is the open web.

## What can I do?

Okay so link rot is bad.
How can I avoid further contributing to link entropy?
Just to be clear the "I" in the section title does not refer to you, the reader,
and that question before wasn't rhetorical.
I'm not going to pretend to have all the answers
and this most certainly isn't a how-to guide.
Think of it more like a kind of public diary of my feeble attempts to fight my own innevitable breaking of this site.

I have tried to be very careful about the layout of the site, URI-wise.
For example, all posts are located at `/posts/<glob>.html` and I never change the glob.
I also try to avoid leaking extensions.
This is rather easy since this is a static site,
but in the future I might add dynamic elements.
In that case I'll try not to introduce extensions like `.cgi` or `.php`.

Still, I fear it might not be enough.
After all, perfection is the enemy of progress.
As I learn and become a better web developer
I will surely realise fallacies in my original layout.
Already, I am growing a tad annoyed at the fact that images and CSS are grouped under `/assets/`.
It's rather arbitrary to decide that images and CSS are "assets" but HTML isn't.

Maybe then I can use 301 for good;
as resources are relocated I can maintain a list of [rewrite rules].
Perhaps I could model it as database migrations.
In the database world, when one modifies a schema
(e.g. adding or removing a column)
that change is associated with a bit of code
specifying how to go from one schema to another.
That way, all the data (existing hyperlinks) remains valid as the schema (site layout) changes.

[rewrite rules]: https://www.nginx.com/blog/creating-nginx-rewrite-rules/

There are also more radical approached like [IPFS].
In this protocol resources are addressed by a [content ID] computed from their content rather than their location.
That way, multiple peers can host it, reducing the likelyhood of the website ever disappearing or going down.
It's all very smart, but I doubt we can convince everyone to switch protocols just like that.

[IPFS]: https://ipfs.tech/
[content ID]: https://docs.ipfs.tech/concepts/content-addressing/#cids-are-not-file-hashes

# Conclusion

The <abbr title="too long; didn't read">tl;dr</abbr> is this:
There's an issue on the web where links tend to 'go bad'.
That is, their location change and hyperlinks to the old location is broken.
This problem is especially prevalent in the IndieWeb community
because we don't have teams of engineers managing our sites and checking for backwards compatibility.

So far my only solution is "be very careful"
which isn't a very inspiring conclusion.
In the coming weeks I'll look into making some automated testing, so I can be
notified when I accidentally change the site layout in such a way that it
breaks old links.
