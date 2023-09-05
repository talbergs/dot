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
[ -d /dot ] && rm -rf /dot
git clone --depth 1 https://github.com/talbergs/dot /dot

# Eval fs conf.
disko=$(nix eval --file ./disko-config.nix --arg disk "\"$dev\"" disk)
echo "{ disko = { devices = { disk = ${disko}; }; }; }" > /tmp/disko.nix

# Revert previous attempts.
[ -f /mnt/swapfile ] && swapoff /mnt/swapfile
umount -R /mnt || true

# Format and mount.
nix run github:nix-community/disko -- --mode disko /tmp/disko.nix

# Make swap.
fallocate -l 8G /mnt/swapfile
chmod 600 $_
mkswap $_
swapon $_

# Generate the config for hardware.
nixos-generate-config --force --no-filesystems --root /mnt

# Fill template.
sed \
    -e "s#{{{ symbol }}}#${symbol}#" \
    -e "s#{{{ dev }}}#${dev}#" \
    /dot/util/configuration.tmpl.nix > /mnt/etc/nixos/configuration.nix
cp /dot/disko-config.nix /mnt/etc/nixos/

# Install.
nixos-install --root /mnt --no-root-passwd --show-trace

echo All done. Reboot.
