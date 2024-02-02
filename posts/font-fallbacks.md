# Common font fallbacks

This page is an HTML adaption of [@yesiamrocks] [CSS fallback fonts][css-fallback-fonts] repository.
It contains a lot of common [CSS fallback chains][w3-font-fallback].
On this page I've taken the liberty of converting the Markdown to some HTML with examples of each CSS chunk.

Keep in mind that if you don't have the fonts installed on your system,
you will see the first fallback that *is* installed.
Any browser worth its salt will let you see this using its development tools.
For example, [here's how to do it in FireFox][ff-fonts-used].

Regretfully, it is not possible to highlight failing fonts, as doing so would allow for easy fingerprinting.
This exact issue has been discussed by the [CSS Working Group][font-check].

This document is split into 3 sections:

- [Sans-serif fonts](#sans-serif)
- [Serif fonts](#serif)
- [Monospace fonts](#monospace)

<?
set pangram "The quick brown fox jumped over the lazy dog."

# Each font gets a little box which should be styled.
emit {
    <style>
        .font-demo {
            border: 2px solid #eee;
            border-radius: .5rem;
            background-color: white;
            color: black;
            padding: 1rem;
        }
    </style>
}

proc emit_fonts {fonts} {
    global pangram

    foreach {name chain} $fonts {
        emitln <h3>[escape_html $name]</h3>

        emitln "<p>To use [escape_html $name] on your webpage, copy the following CSS rule.</p>"

		emitln "<pre><code>body {"
		emitln "\tfont-family: $chain;"
		emitln "}</code></pre>"

		emitln {<p>The following is an example of the font in use.</p>}

        emitln {<div class="font-demo">}
        emitln "<span style=\"font-family: [escape_html $chain];\">[escape_html $pangram]</span>"
        emitln {</div>}
    }
}
?>

[@yesiamrocks]: https://github.com/yesiamrocks
[css-fallback-fonts]: https://github.com/yesiamrocks/CSS-Fallback-Fonts/
[w3-font-fallback]: https://www.w3schools.com/css/css_font_fallbacks.asp
[ff-fonts-used]: https://firefox-source-docs.mozilla.org/devtools-user/page_inspector/how_to/edit_fonts/index.html#fonts-used
[font-check]: https://github.com/w3c/csswg-drafts/issues/5744

## Sans-serif fonts <a id="sans-serif" />

<?
set sans_serif_fonts {
    {Arial} {Arial, "Helvetica Neue", Helvetica, sans-serif}
    {Arial Black} {"Arial Black", "Arial Bold", Gadget, sans-serif}
    {Arial Narrow} {"Arial Narrow", Arial, sans-serif}
    {Arial Rounded MT Bold} {"Arial Rounded MT Bold", "Helvetica Rounded", Arial, sans-serif}
    {Century Gothic} {"Century Gothic", CenturyGothic, AppleGothic, sans-serif}
    {Calibri} {Calibri, Candara, Segoe, "Segoe UI", Optima, Arial, sans-serif}
    {Candara} {Candara, Calibri, Segoe, "Segoe UI", Optima, Arial, sans-serif}
    {Avant Garde} {"Avant Garde", Avantgarde, "Century Gothic", CenturyGothic, AppleGothic, sans-serif}
    {Helvetica} {"Helvetica Neue", Helvetica, Arial, sans-serif}
    {Franklin Gothic Medium} {"Franklin Gothic Medium", "Franklin Gothic", "ITC Franklin Gothic", Arial, sans-serif}
    {Futura} {Futura, "Trebuchet MS", Arial, sans-serif}
    {Impact} {Impact, Haettenschweiler, "Franklin Gothic Bold", Charcoal, "Helvetica Inserat", "Bitstream Vera Sans Bold", "Arial Black", "sans serif"}
    {Tahoma} {Tahoma, Verdana, Segoe, sans-serif}
    {Segoe UI} {"Segoe UI", Frutiger, "Frutiger Linotype", "Dejavu Sans", "Helvetica Neue", Arial, sans-serif}
    {Geneva} {Geneva, Tahoma, Verdana, sans-serif}
    {Optima} {Optima, Segoe, "Segoe UI", Candara, Calibri, Arial, sans-serif}
    {Gill Sans} {"Gill Sans", "Gill Sans MT", Calibri, sans-serif}
    {Trebuchet MS} {"Trebuchet MS", "Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", Tahoma, sans-serif}
    {Lucida Grande} {"Lucida Grande", "Lucida Sans Unicode", "Lucida Sans", Geneva, Verdana, sans-serif}
    {Verdana} {Verdana, Geneva, sans-serif}
}

emit_fonts $sans_serif_fonts
?>

## Serif fonts <a name="serif" />

<?
set serif_fonts {
    {Big Caslon} {"Big Caslon", "Book Antiqua", "Palatino Linotype", Georgia, serif}
    {Didot} {Didot, "Didot LT STD", "Hoefler Text", Garamond, "Times New Roman", serif}
    {Lucida Bright} {"Lucida Bright", Georgia, serif}
    {Baskerville} {Baskerville, "Baskerville Old Face", "Hoefler Text", Garamond, "Times New Roman", serif}
    {Hoefler Text} {"Hoefler Text", "Baskerville Old Face", Garamond, "Times New Roman", serif}
    {Goudy Old Style} {"Goudy Old Style", Garamond, "Big Caslon", "Times New Roman", serif}
    {Cambria} {Cambria, Georgia, serif}
    {Rockwell} {Rockwell, "Courier Bold", Courier, Georgia, Times, "Times New Roman", serif}
    {Times New Roman} {TimesNewRoman, "Times New Roman", Times, Baskerville, Georgia, serif}
    {Perpetua} {Perpetua, Baskerville, "Big Caslon", "Palatino Linotype", Palatino, "URW Palladio L", "Nimbus Roman No9 L", serif}
    {Bodoni MT} {"Bodoni MT", Didot, "Didot LT STD", "Hoefler Text", Garamond, "Times New Roman", serif}
    {Georgia} {Georgia, Times, "Times New Roman", serif}
    {Palatino} {Palatino, "Palatino Linotype", "Palatino LT STD", "Book Antiqua", Georgia, serif}
    {Rockwell Extra Bold} {"Rockwell Extra Bold", "Rockwell Bold", monospace}
    {Garamond} {Garamond, Baskerville, "Baskerville Old Face", "Hoefler Text", "Times New Roman", serif}
    {Book Antiqua} {"Book Antiqua", Palatino, "Palatino Linotype", "Palatino LT STD", Georgia, serif}
    {Calisto MT} {"Calisto MT", "Bookman Old Style", Bookman, "Goudy Old Style", Garamond, "Hoefler Text", "Bitstream Charter", Georgia, serif}
}

emit_fonts $serif_fonts
?>

## Monospace fonts <a id="monospace" />

<?
emit_fonts {
    {Lucida Console} {"Lucida Console", "Lucida Sans Typewriter", monaco, "Bitstream Vera Sans Mono", monospace}
    {Andale Mono} {"Andale Mono", AndaleMono, monospace}
    {Courier New} {"Courier New", Courier, "Lucida Sans Typewriter", "Lucida Typewriter", monospace}
    {Monaco} {monaco, Consolas, "Lucida Console", monospace}
    {Consolas} {Consolas, monaco, monospace}
    {Lucida Sans Typewriter} {"Lucida Sans Typewriter", "Lucida Console", monaco, "Bitstream Vera Sans Mono", monospace}
}
?>

## Conclusion

Those are all the fonts @yesiamrocks included!
I'll leave you to your decision parallysis now...
