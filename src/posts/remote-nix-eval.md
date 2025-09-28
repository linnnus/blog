# Remote Nix evaluation

; Maybe the model name + picture?
; I don't think we need/care about the motivation for using such a weak machine.
I'm writing this post on a computer with 1 GiB of DDR2 RAM and an Intel Atom N450.
I can't event preview it before I publish it because this computer can't run Firefox.
So yeah,,, needless to say running NixOS rebuilds on this machine takes _a while_.
Usually, the solution to this is [remote builds]:
let another, more powerful machine do the actual building
and just `nix copy` the results.

Alas, not even remote builds can't save this poor computer.
Remote builds still require [instantiation] (i.e. evaluating a a `.nix` to a `.drv`) to happen locally
and my poor baby completely locks up while trying to
squeeze out the huge [graph reduction] that is evaluating my system configuation.

; FIXME: Is Nix evaluation actually implemented with graph reduction?

In order to make using NixOS on this machine livable
(which arguably is not a valuable use of anyone's time),
I've come up with my own equivalent to `nixos-rebuild`
which does both the building _and_ the evaluation on the remote.
I can't decide if it's brilliant or a giant hack
but either way [here it is][remote_build.sh].

When writing the script,
I took care to keep it as a linear sequence of steps
so I figure we can just walk through it now to explain how it works
and then you can decide for yourself
whether it's a stroke of genius or just... a regular stroke... I guess[^hahamrfunnyguy].
Anyways, first up is some boilerplate:

[^hahamrfunnyguy]: Yeah I didn't really know where I was going with that either.

```bash
#!/bin/sh
set -u -e -o pipefail
cd -- "$(dirname -- "$0")"
msg () { tput smso; printf '%s\n' "$1"; tput rmso; }
```

Then we define some parameters for how to
connect to the remote machine over SSH.
Ideally, I'd probably use a less privileged user for this
but it still has to be interactive
as it runs the Nix CLI.

```bash
identity="/home/linus/.ssh/id_ed25519"
remote_user=linus
remote_ip=203.0.113.5
remote_port=22
```

Now the actual commands begin!
First, we copy our local flake to the store.
This is our entering Nix land.

```bash
msg "Copying configuration to store..."
pathToSource="$(nix flake archive --json . | jq -r .path)"
echo "Source is $pathToSource"
```

From our own store the flake source is transferred to the remote builders store
with `nix-copy-closure`[^nix3].

[^nix3]: I haven't been strict in using the newer Nix3 commands.
It would probably have been more appropriate to use `nix copy` instead.

```bash
msg "Copying system to remote ($remote_user@$remote_ip:$remote_port)..."
NIX_SSHOPTS="-p $remote_port -i $identity" nix-copy-closure --to "$remote_user@$remote_ip" "$pathToSource"
```

In a previous iteration
I had the script `rsync`ing the flake directory to the remote builders `/tmp`
which was faster (due to `rsync` only copying changed files) but felt waaay more hacky.

Either way,
with the flake source located on the remote builder,
we can SSH in and
do both the instantiation _and_ building
using the regular `nix build` command.
This is the heart of the script and the thing which is either a total hack or a stroke of genius.
The command `nix build` composes instantiation & realisation
and both are done on the remote machine,
alleviating the computational burden of instantiation from the local machine.

```bash
msg "Building system on remote..."
pathToConfig="$(ssh -p "$remote_port" -i "$identity" "$remote_user@$remote_ip" \
                nix build --keep-going --no-link --print-out-paths \
		"$pathToSource#nixosConfigurations.$(hostname).config.system.build.toplevel")"
echo "New configuration is $pathToConfig"
```

After the system has been built, we can copy it back to the local machine.
This requires that we run as a "trusted user";
either root or a person listed in the `trusted-users` Nix setting.
That's because copying indirectly gives root access since one could overwrite any store artifact,
including e.g. the activation script
that's executed on startup.

```bash
msg "Copying system closure from remote (must be trusted user)..."
NIX_SSHOPTS="-p $remote_port -i $identity" nix-copy-closure --from "$remote_user@$remote_ip" "$pathToConfig"
```

At long last we can activate the new configuration in our local store!
Now all that's left is to activate it.

The built system-configuration will contain a script called `switch-to-configuration`
which does exactly what it says on the tin.
However, it expects us to install the system profile first.
At least that's what I gather from a quick reading of `nixos-rebuild`[^nixos-rebuild].
As of NixOS/nixpkgs@35bd00d6c the relevant section is [lines 921 thru 979 of nixos-rebuild.sh][switch-to].

; FIXME: Hej jeg forstår ikke engelsk konjunktiv.
[^nixos-rebuild]: `nixos-rebuild` is a _monster_ shell script.
For something so essential to NixOS,
I'd really have hoped it was less opaque.

```bash
msg "Updating system profile (sudo)..."
sudo nix-env --profile /nix/var/nix/profiles/system --set "$pathToConfig"

msg "Activating new system (sudo)..."
sudo "$pathToConfig"/bin/switch-to-configuration "${1:-boot}"
```

Now, the real `nixos-rebuild` does some more stuff when invoking `switch-to-configuration`.
In particular:

* `nixos-rebuild` modifies `NIXOS_INSTALL_BOOTLOADER` and `LOCALE_ARCHIVE`.
* `nixos-rebuild` wraps the invocation in `systemd-run`.

If they come back to bite me in the ass,
I'll update the script
but for now its been working perfectly.

[graph reduction]: https://amelia.how/posts/the-gmachine-in-detail.html
[remote_build.sh]: ../documents/remote_build.sh
[remote builds]: https://nix.dev/manual/nix/2.28/advanced-topics/distributed-builds.html
[instantiation]: https://nix.dev/manual/nix/2.28/command-ref/nix-instantiate.html
[switch-to]: https://github.com/NixOS/nixpkgs/blob/35bd00d6c73361b3e0c1b8dec95b37bdcaa9799f/pkgs/os-specific/linux/nixos-rebuild/nixos-rebuild.sh#L921-L979
