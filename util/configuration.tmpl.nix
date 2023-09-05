{ pkgs, ... } : {
  imports = [
    ./hardware-configuration.nix
    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/master.tar.gz"}/module.nix"
  ];

  boot.loader.grub.devices = [ "{{{ dev }}}" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

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

  system.stateVersion = "23.05";
}
