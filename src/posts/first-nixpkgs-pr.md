# My first nixpkgs PR

I spend a lot of time in the open source ecosystem but,
as I've realized,
mostly as a passive consumer.
I use all these amazing open source projects
but I never give anything back,
except maybe the odd issue.
That's beta behavior and I'm looking to change that.

## Finding a first issue

; TODO: overgang her
In responding to [a question on the NixOS Discourse][discourse-post],
I noticed that nix-darwin doesn't escape XML special characters in `system.defaults` options.
Removing the special characters proved to be the solution to that specific question
but obviously that behavior is counter-intuitive.
Normally, I'd leave it at that.
Case closed.
This time, however,
I set about fixing the root cause.

I pretty quickly traced the issue back to the function [`toPlist` found in `nixpkgs/lib/generators.nix`][toPlist-orig].
The initial, naive solution looked like this:

```diff
diff --git lib/generators.nix
--- a/lib/generators.nix
+++ b/lib/generators.nix
@@@ -32,6 -32,6 +32,7 @@@ le
      const
      elem
      escape
++    escapeXML
      filter
      flatten
      foldl
@@@ -570,8 -570,8 +571,8 @@@ in rec

      bool = ind: x: literal ind  (if x then "<true/>" else "<false/>");
      int = ind: x: literal ind "<integer>${toString x}</integer>";
--    str = ind: x: literal ind "<string>${x}</string>";
--    key = ind: x: literal ind "<key>${x}</key>";
++    str = ind: x: literal ind "<string>${escapeXML x}</string>";
++    key = ind: x: literal ind "<key>${escapeXML x}</key>";
      float = ind: x: literal ind "<real>${toString x}</real>";

      indent = ind: expr "\t${ind}";
```

## Getting feedback

Almost immediately upon opening the PR,
@emilazy pointed out that this is technically a breaking change
and `nixpkgs/lib` specifically as pretty strict backwards-compatibility guarantees.
It turns out that some people in the wild
were actually _relying_ on the non-escaping of XML characters
by writing code like this:

```nix
launchd.agents."some-daemon".serviceConfig.programArguments = [
  "/bin/sh"
  "-c"
  "wait4path /nix/store &amp;&amp; /nix/store/.../bin/some-daemon"
];
```

Silently breaking their code
-- even if it happened at a release boundary --
was a no-go.
Instead, we settled on a transitionary approach where
an argument `escape = false` was introduced (thus avoiding breakage) and
a warning introduced to activate after a certain release
to encourage users to migrate.

```diff
diff --git a/lib/generators.nix b/lib/generators.nix
index 4317e49c2538f3..376aa4081bf4f4 100644
--- a/lib/generators.nix
+++ b/lib/generators.nix
@@ -548,13 +549,17 @@ in rec {
-  toPlist = {}: v: let
+  toPlist = {
+    escape ? false
+  }: v: let
     expr = ind: x:
       if x == null  then "" else
       if isBool x   then bool ind x else
@@ -568,10 +573,12 @@ in rec {
 
     literal = ind: x: ind + x;
 
+    maybeEscapeXML = if escape then escapeXML else x: x;
+
     bool = ind: x: literal ind  (if x then "<true/>" else "<false/>");
     int = ind: x: literal ind "<integer>${toString x}</integer>";
-    str = ind: x: literal ind "<string>${x}</string>";
-    key = ind: x: literal ind "<key>${x}</key>";
+    str = ind: x: literal ind "<string>${maybeEscapeXML x}</string>";
+    key = ind: x: literal ind "<key>${maybeEscapeXML x}</key>";
     float = ind: x: literal ind "<real>${toString x}</real>";
 
     indent = ind: expr "\t${ind}";
@@ -597,7 +604,10 @@ in rec {
       (expr "\t${ind}" value)
     ]) x));
 
-  in ''<?xml version="1.0" encoding="UTF-8"?>
+  in
+  # TODO: As discussed in #356502, deprecated functionality should be removed sometime after 25.11.
+  lib.warnIf (!escape && lib.oldestSupportedReleaseIsAtLeast 2505) "Using `lib.generators.toPlist` without `escape = true` is deprecated"
+  ''<?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 ${expr "" v}
```

With the fix ironed out
I then created [a PR to nix-darwin][darwin-pr] and [another PR to Home Manager][hm-pr][^hm]
updating them to invoke `toPlist` with the new behavior enabled (i.e. `escape = true`).
In both projects it was already a pretty common pattern to use `&amp;&amp;`
when creating agents/daemons like in the example I showed above,
so [I added some extra warnings][eval-warning] specifically to catch that.

[^hm]: I also updated HM as it, together with nix-darwin,
makes up the majority of actual use of `toPlist` in the wild.
The patches are basically identical.

The PRs to the downstream projects were merged pretty quickly too.
As of 21/08/2025 all the PRs have finally been merged
and the roll-out should be complete in the 25.11 release.

## Learnings

This has been a really interesting and valuable experience.
It was very exciting going from a user reporting an issue all the way to users now getting the fix
(and hopefully not noticing at all).

Something I didn't appreciate fully before is that
open source is a unique opportunity to work with and learn from engineers
that are much more skilled than myself.
In particular,
I had some really nice discussions with @emilazy on [Hyrum's Law][hyrum] and API breakages
on GitHub and the nix-darwin Matrix server.

On the other hand,
this was kind of a lot of work to fix a very small issue that'll only bite a couple of users.
Hopefully that's just because I'm so green.
A lot of the delay was due to me loosing focus and getting confused about release schedules.
Most contributions also don't require coordinating between three different projects.
I guess the only way to figure that out
is to make more contributions!

[toPlist-orig]: https://github.com/NixOS/nixpkgs/blob/7042c42ea53f7edcac7e363960c68e1a68a5fce5/lib/generators.nix#L546-L604
[discourse-post]: https://discourse.nixos.org/t/correctly-running-cloned-flake/55960/11?u=linnnus
[hm-pr]: https://github.com/nix-community/home-manager/pull/7356
[darwin-pr]: https://github.com/nix-darwin/nix-darwin/pull/1529
[nixpkgs-pr]: https://github.com/NixOS/nixpkgs/pull/356502
[hyrum]: https://www.hyrumslaw.com/
[eval-warning]: https://github.com/nix-darwin/nix-darwin/pull/1529/commits/f0b44d685478fd3b5fc7860b80821084c24790da
