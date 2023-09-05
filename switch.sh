#!/usr/bin/env bash
set -e

# Take OS installation files.
cp -r /etc/nixos ./nixos

sudo nixos-rebuild switch --flake .#nixos
