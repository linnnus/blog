# A surprisingly simple way to package Deno applications for Nix

## Introduction

Recently, I was working on a [Deno] project which I wanted to package for Nix.
Usually, when packaging a piece of software for Nix,
there exists a language-specific `stdenv.mkDerivation` derivative
which works to bridge the gap between between the langauge-specific package managers and Nix.
These are functions like [`buildNpmPackage`][buildNpmPackage] and [`buildPythonPackage`][buildPythonPackage]
but, alas, there is no `buildDenoPackage`.

Deno is particularly tricky
(as compared to for example TCL),
because it uses ["URL imports"][deno-modules]
to import directly from URLs as runtime.
Doing so is obviously not deterministic
which means that bundling Deno applications becomes a bit of a challenge.

In this post, I will go over
why none of the existing, community-driven solutions worked for me,
what I did instead,
and some of the potential drawbacks of my solution.

; FIXME: Somewhere around here we should mention that Deno downloads dependencies from the internet at runtime.

[Deno]: https://deno.land/
; FIXME: We should pin to a specific version of the manual.
[buildNpmPackage]: https://nixos.org/manual/nixpkgs/stable/#javascript-buildNpmPackage
[buildPythonPackage]: https://nixos.org/manual/nixpkgs/stable/#buildpythonpackage-function
[deno-modules]: https://docs.deno.com/runtime/manual/basics/modules/#remote-import

## Existing solution

During my initial research, I found [this thread][discourse-thread] disussing my exact issue:
wrapping Deno applications in Nix.
The thread settles on using [`deno2nix`][deno2nix].
`deno2nix` works by parsing the lockfiles that Deno generates[^lockfiles] and generating a matching Nix derivation.

; FIXME: There's a lot of "this" in this paragraph.
; We kind of end up repeating what we *just* said above.
There's a lot of work involved in what `deno2nix` does;
it has to parse Deno's lockfile format,
clean it up,
then generate a matching Nix derivation.
All of this code has potential for bugs.
Nothing illustrates this better than [this issue][esm.sh-issue].
It essentially boils down to Deno's resolution algorithm setting a different [`User-Agent` header][ua] than what the Nix builder did.
`esm.sh` was [using the user-agent to send different content][esm.sh-ua] to Deno than to the browser

The underlying issue here is that `deno2nix` is trying to replicate the exact behavior of Deno, which is a hard task.

`deno2nix` also [does not support NPM modules][npm-support] (i.e. imports using an `npm:` specifier) at the time of writing.
Doing so will likely cause the amount of code in the repo to double, since NPM
packages are handled entirely differently both in the lockfile format and Deno's resolution algorithm.

[^lockfiles]: For the uninitiated, I suggest reading [the official introduction to Deno's lockfiles][deno-lockfiles].
In essence, lockfiles are just a mapping from URLs to their expected hashes.
Their purpose is for locking dependencies to specific versions.
Since this sounds a lot like what Nix is trying to do
(though admittedly at a much smaller scale)
they are usually the input for the various `mkDerivation` derivatives.

[discourse-thread]: https://discourse.nixos.org/t/packaging-deno-applications/15441
[deno2nix]: https://github.com/SnO2WMaN/deno2nix/
[deno-lockfiles]: https://docs.deno.com/runtime/manual/basics/modules/integrity_checking
[esm.sh-issue]: https://github.com/SnO2WMaN/deno2nix/issues/30
[ua]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent
[esm.sh-ua]: https://esm.sh/#esbuild-options
[npm-support]: https://github.com/SnO2WMaN/deno2nix/issues/18

## My solution

After fighting with `deno2nix` for a while,
I decided to take a different approach.

; FIXME: We should introduce import maps better
Deno supports a pretty niche subcommand: [`deno vendor`][deno-vendor].
This command downloads all dependencies of the given file into a folder.
This is called [vendoring][so-vendoring],
hence the name of the command.
It also generates an import map[^import-maps]
which can be used to make Deno use these local dependencies,
rather than fetching from online.

This command is very convenient for us
because we can use it to download and fix bundles ahead of time.
To make evaluation pure, we can fix the hash of the output
(i.e. a [fixed output derivation][fixed-output-derivation]).

In case this sounds too abstract,
here's an example.
Suppose we have a simple program which just prints a random string.
`main.ts` just contains:

```typscript
import { bgMagenta } from "https://deno.land/std@0.214.0/fmt/colors.ts";
import { generate } from "https://esm.sh/randomstring";

const s = generate();
console.log("Here is your random string: " + bgMagenta(s));
```

; FIXME: "vendor directory" is the output of `deno vendor`, but we haven't used that term before.
First, we'll build the vendor directory.
We pull out the `src` attribute into a separate variable,
as it is shared between both derivations.
The fact that we specify the `outputHash` attribute means that this is going to be a fixed-output derivation.
As such, the builder will be allowed network access in return to guaranteeing that the output has a specific hash.

```nix
# This could of course be anywhere, like a GitHub repository.
src = ./.;

# Here we build the vendor directory as a separate derivation.
random-string-vendor = stdenv.mkDerivation {
  name = "random-string-vendor";

  nativeBuildInputs = [ deno ];

  inherit src;
  buildCommand = ''
    # Deno wants to create cache directories.
    # By default $HOME points to /homeless-shelter, which isn't writable.
    HOME="$(mktemp -d)"

    # Build vendor directory
    deno vendor --output=$out $src/main.ts
  '';

  # Here we specify the hash, which makes this a fixed-output derivation.
  # When inputs have changed, outputHash should be set to empty, to recalculate the new hash.
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-a4jEqwyp5LoORLYvfYQmymzu9448BoBV5luHnt4BbMg=";
};
```

Let's try building this and taking a peek inside.
In the transcript below, you will see
that the output contains a directory hierarchy corresponding to our dependencies.
It also contains `import_map.json` at the top level.

```sh
$ nix-build vendor.nix
/nix/store/…-random-string-vendor
$ tree /nix/store/…-random-string-vendor
/nix/store/…-random-string-vendor
├── deno.land
│   └── std@0.214.0
│       └── fmt
│           └── colors.ts
├── esm.sh
│   ├── v135
│   │   ├── @types
│   │   │   └── randomstring@1.1.11
│   │   │       └── index.d.ts
│   │   ├── randombytes@2.0.3
│   │   │   └── denonext
│   │   │       └── randombytes.mjs
│   │   └── randomstring@1.3.0
│   │       └── denonext
│   │           └── randomstring.mjs
│   ├── randomstring@1.3.0.js
│   └── randomstring@1.3.0.proxied.js
└── import_map.json
```

Now we can build the actual application.
We are going to create a little wrapper script
which will invoke Deno with the right arguments.
We use `--import-map` to have Deno use our local dependencies
and `--no-remote` to force Deno not to fetch dependencies at run-time,
in case `random-string-vendor` is outdated
(i.e. doesn't include all dependencies imported by the script).

```nix
random-string = writeShellScript "random-string" ''
  ${deno}/bin/deno run \
    --import-map=${random-string-vendor}/import_map.json \
    --no-remote \
    ${src}/main.ts -- "$@"
'';
```

That's basically all there is to it!
The great thing about this approach is
that it (by definition) uses Deno's exact resolution algorithm.
We don't run into trouble with `esm.sh` because Deno sets the correct UA.
That's an entire class of bugs eliminated!

[^import-maps]: Import maps allow you to tell Deno
"when you see an import statement for A, you should actually import B."
The actual file is just a JSON object where the keys are A and the values are B.
If this is new to you, you might want to check out [the official documentation][import-maps].

[deno-vendor]: https://docs.deno.com/runtime/manual/tools/vendor
[import-maps]: https://docs.deno.com/runtime/manual/basics/import_maps
[so-vendoring]: https://stackoverflow.com/q/26217488
[fixed-output-derivation]: https://nixos.org/manual/nix/stable/language/advanced-attributes.html?highlight=outputHash

## Shortcomings

It's not all sunshine and rainbows, though.
There are some significant drawbacks to this approach
which I will go over in this section.

First of all,
the vendor subcommand is woefully undercooked.
`npm:` specifiers are just silently ignored.
It is outlined in [this issue][npm-vendor-issue],
which has been open for quite some time.
In general, it doesn't seem like this command has been getting a whole lot of love since its introduction,
probably on account of being so niche.

Nevertheless,
when Deno does finally get support for vendoring NPM modules,
this module will automatically also support them.
This is in stark contrast with `deno2nix`
which would require a lot of work to support `npm:` specifiers.

The second major issue is that this approach doesn't make good use of caching.
The `random-string-vendor`-derivation we constructed above is essentially a huge blob;
if we change a single dependency,
the entire derivation is invalidated.
If I understand `deno2nix` correctly,
it actually makes a derivation for each dependency
and then uses something akin to `symlinkJoin` to combine them.
Such an approach allows individual dependencies to be cached and shared in the Nix store.

The issue of caching is tangentially related to some of the issues outlined by @volth's [Status of lang2nix approaches][lang2nix].
A lot of their criticism also applies here.

[npm-vendor-issue]: https://github.com/denoland/deno/issues/19740
[lang2nix]: https://discourse.nixos.org/t/status-of-lang2nix-approaches/14477

## Conclusion

In this post I have described a simple approach to packaging Deno applications for Nix.
I much prefer it to `deno2nix` simply because I understand exactly how it works.
Even then, there are some major drawbacks to using this method.
Before implementing this approach in your project,
you should consider if those trade-offs make sense for you.
