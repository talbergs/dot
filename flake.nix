{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./nixos/configuration.nix
          ./config/keyd.nix
          ({ config, pkgs, ... }: {
            systemd.services.ssh-agent = {
              enable = true;
              description = "SSH agent";
              wantedBy = [ "basic.target" ];
              serviceConfig.Type = "simple";
              serviceConfig.ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent.socket";
            };
          })
        ];
      };
    };
  };
}
