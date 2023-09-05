#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "What symbol will be used as password, user, hostname..." 
read -p "Provide symbol in characters [a-z]+: " symbol

cd /mnt/etc/nixos
set -x

# Fix the live-cd config.
export NIX_CONFIG="extra-experimental-features = nix-command flakes"

# Pull some runtime for this script.
nix-env -i fzf git

# Pick the disk to install to.
dev=$(lsblk -d -o path,size,model | fzf --prompt "Choose the disk > ")
dev=${dev%% *}

# Pull dots into root fs.
git clone https://github.com/talbergs/dot /mnt/dot

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
    /mnt/dot/util/configuration.tmpl.nix > ./configuration.nix

# nixos-install --root /mnt --flake /mnt/dot#nixos
nixos-install --root /mnt --no-root-passwd

# reboot
