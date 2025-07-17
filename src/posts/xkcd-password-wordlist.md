# "Korrekt Hest Batteri Hæfteklamme": Finding a Danish wordlist for XKCD-style passwords

; FIXME: Should probably proof-read at some point.
; FIXME: Intro is a little boring.

I've started creating [passphrases][wp-passphrase]
(as popularized by [XKCD #936][xkcd-passprase])
whenever I sign up for a new service.
This password generation method has you randomly selecting words from a big wordlist
to form nonsense phrases.
The result are memorable passphrases like "correct horse battery staple"
which are much easier to remember than something like "Tr0ub4dor&3"
and also provide better security guarantees[^entropy].

[^entropy]: If you don't trust the math behind it,
don't worry [you aren't alone][xkcd-criticism].
It can be a bit unintuitive.
See the above links for an explanation.

; FIXME: "We have a11y at home" ahh alt text.
![XKCD 936](https://imgs.xkcd.com/comics/password_strength_2x.png)

I think they're really neat, but something has always bugged me:
as a non-native speaker,
English passphrases can be really hard to remember.
Often times `xkcdpass` will spit out a passphrase containing an English word I don't know.
Like this one: `CinchDistressEasiestSmittenMuzzle`. What the hell a "cinch"??
I'm almost tempted to simply regenerate the password,
which anyone who's read Cryptonomicon knows is a terrible idea!
So I set about finding a Danish wordlist to use.
Ideally it would contain only the lemmas of nouns and adjectives
since they make for the nicest passphrases.

After messing about with various tools,
trying to extract the information I wanted from [Hunspell's dictionaries][hunspell],
I found the [Wiktionary database dump][wiktionary-dump]
which seemed to contain all the information I wanted.
There's even a nice JSON conversion by [the wikiextract project][wikiextract].
They provide a dump in which every line is a JSON object representing an entry on Wiktionary.
For example, here's the entry for "quandle"
(formatted for your convenience, the actual dump has one entry per line):

```json
{
  "senses": [
    {
      "topics": [ ... ],
      "links": [ ... ],
      "categories": [
        "English countable nouns",
        "English entries with incorrect language header",
        ...
      ],
      "raw_glosses": [ ... ],
      "glosses": [ ... ],
      "wikipedia": [ ... ]
    }
  ],
  "pos": "noun",
  "head_templates": [ ... ],
  "forms": [ ... ],
  "etymology_text": "Coined by David Joyce in his 1982 paper A classifying invariant of knots: the knot quandle.",
  "word": "quandle",
  "lang": "English",
  "lang_code": "en"
}
```

Once I had that data,
I used this pipeline to extract a suitable word list:

```shell
pv raw-wiktextract-data.jsonl \
    | jq 'select(.lang_code == "da")
        | select(.pos == "noun" or .pos == "adj")
        | select(.senses.[].categories | index("Danish lemmas") != null)
        | select(.word | test("\\A[a-zæøåA-ZÆØÅ]\+\\Z"))
        | .word' --raw-output \
    | sort -u \
    > danish.txt
```

`pv` just acts as a `cat`-replacement with a nice progress bar and
the `jq` pipeline in the middle does most of the heavy lifting.
It works something like this:

1. Filter for Danish entries.
2. Filter for nouns and adjectives.
3. Filter for words in the category "Danish lemmas".
   This part removes entries like "væggene" which is derived from "væg".
4. Ignore words with special characters in them like "12-talspige".
5. Pick out the word and throw away all the metadata.
   This last part works in conjunction with the flag `--raw-output`
   which avoids quotes around the strings produced by the filter.

(3) kind of makes (1) redundant, but I built the script iteratively
and since it only has to run once (and be kind of slow either way)
speed wasn't really a concern[^speedup].

[^speedup]: If you wanted to speed this up,
placing a simpler filter before `jq` in the shell pipeline makes a pretty big difference.
Placing `rg --fixed-strings "Danish"` before `jq`
(since every JSON object only takes up a single line and I know valid entries will contain the string "Danish lemmas"),
changed the speed from 60MiB/s to 200GiB/s (as reported by `pv`).

And that's it!
Now I have a beautiful list of 8885 Danish words for password generation.
My only snag with the wordlist is that it still contains some rather archaic words.
If I can find some frequency data I might try to filter for the top X% most common words.
Either way, archaic *Danish* words are still a heck of a lot easier for me to remember than archaic *English* words.

[wp-passphrase]: https://en.wikipedia.org/wiki/Passphrase
[xkcd-passprase]: https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength
[xkcd-criticism]: https://www.explainxkcd.com/wiki/index.php/936:_Password_Strength#People_who_don.27t_understand_information_theory_and_security
[hunspell]: https://hunspell.github.io/
[wiktionary-dump]: https://dumps.wikimedia.org/enwiktionary/
[wikiextract]: https://github.com/tatuylonen/wiktextract
