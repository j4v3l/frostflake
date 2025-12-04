{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../common/darwin.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  networking.hostName = "glacier";

  users.users.jager = {
    name = "jager";
    home = "/Users/jager";
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.jager = import ../../home/jager/darwin/default.nix;
  };

  system.stateVersion = 5;
}
