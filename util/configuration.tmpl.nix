{ pkgs, ... } : {
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball {
      url = "https://github.com/nix-community/disko/archive/1c38664f.tar.gz";
      sha256 = "1gq2bm29rh8nhlqxh35r372b1gx5zkhjxqabhnqprmlxs2lf2xfl";
    }}/module.nix"
  ];

  boot.loader.grub.devices = [ "{{{ dev }}}" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  services.sshd.enable = true;

  disko.devices = import ./disko-config.nix {
    disk = "{{{ dev }}}";
  };

  networking.hostName = "{{{ symbol }}}";
  networking.networkmanager.enable = true;

  users.users."{{{ symbol }}}" = {
    initialPassword = "{{{ symbol }}}";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ neovim ];
  };

  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = "23.05";
}
