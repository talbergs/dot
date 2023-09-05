#!/usr/bin/env bash
set -e

dev=${1}
symbol=${2}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -z "$symbol" ]; then
    echo "What symbol will be used as password, user, hostname..."
    read -p "Provide symbol in characters [a-z]+: " symbol
fi

set -x

# Fix the live-cd config.
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

# Pick the disk to install to.
if [ -z "$dev" ]; then
    # Pull some runtime for this script.
    nix-env -i fzf
    dev=$(lsblk -d -o path,size,model | sed 1d | fzf --prompt "Choose the disk > ")
    dev=${dev%% *}
fi

# Pull dots into root fs.
[ -d /mnt/dot ] && rm -rf /mnt/dot
git clone --depth 1 https://github.com/talbergs/dot /mnt/dot

# Format and mount.
nix run github:nix-community/disko -- --mode disko /mnt/dot/disko-config.nix --arg disk $dev

# Make swap.
fallocate 8G /mnt/swapfile
chmod 600 $_
mkswap $_
swapon $_

# Generate the config for hardware.
nixos-generate-config --no-filesystems --root /mnt

# Fill template.
sed \
    -e "s#{{{ symbol }}}#${symbol}#" \
    -e "s#{{{ dev }}}#${dev}#" \
    /mnt/dot/util/configuration.tmpl.nix > /mnt/etc/nixos/configuration.nix

nixos-install --root /mnt --no-root-passwd --show-trace

echo All done. Reboot.
