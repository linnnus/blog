#!/bin/sh
set -u -e -o pipefail
cd -- "$(dirname -- "$0")"
msg () { tput smso; printf '%s\n' "$1"; tput rmso; }

identity="/home/linus/.ssh/id_ed25519"
remote_user=linus
remote_ip=192.168.68.222
remote_port=22
#remote_ip=77.33.188.139
#remote_port=2207

msg "Copying configuration to store..."
pathToSource="$(nix flake archive --json . | jq -r .path)"
echo "Source is $pathToSource"

msg "Copying system to remote ($remote_user@$remote_ip:$remote_port)..."
NIX_SSHOPTS="-p $remote_port -i $identity" nix-copy-closure --to "$remote_user@$remote_ip" "$pathToSource"

msg "Building system on remote..."
pathToConfig="$(ssh -p "$remote_port" -i "$identity" "$remote_user@$remote_ip" \
                nix build --keep-going --no-link --print-out-paths \
		"$pathToSource#nixosConfigurations.$(hostname).config.system.build.toplevel")"
echo "New configuration is $pathToConfig"

# NOTE: This requires that we run as a "trusted user"; either root
#       or a person listed in the trusted-users Nix setting.
msg "Copying system closure from remote (must be trusted user)..."
NIX_SSHOPTS="-p $remote_port -i $identity" nix-copy-closure --from "$remote_user@$remote_ip" "$pathToConfig"

msg "Updating system profile (sudo)..."
sudo nix-env --profile /nix/var/nix/profiles/system --set "$pathToConfig"

# TODO: nixos-rebuild modifies NIXOS_INSTALL_BOOTLOADER and LOCALE_ARCHIVE. Should we?
# TODO: nixos-rebuild wraps the invocation in systemd-run. Should we?
msg "Activating new system (sudo)..."
sudo "$pathToConfig"/bin/switch-to-configuration "${1:-boot}"
