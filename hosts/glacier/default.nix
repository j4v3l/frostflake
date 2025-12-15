{
  inputs,
  pkgs,
  frostflakeUser,
  frostflakeRoot,
  ...
}: let
  user = frostflakeUser;
in {
  imports = [
    ../common/darwin.nix
    ../../modules/system/ai.nix
    inputs.home-manager.darwinModules.home-manager
    inputs."sops-nix".darwinModules.sops
  ];

  networking.hostName = "glacier";

  users.users.${user.username} = {
    name = user.fullName or user.username;
    home = user.darwinHome;
    shell = user.shellPackage pkgs;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit frostflakeUser frostflakeRoot;};
    users.${user.username} = import ../../home/jager/darwin/default.nix;
  };

  frostflake.ai = {
    enable = false;
    packages.enable = false;
    ollama.enable = false;
  };

  system.stateVersion = 5;
}
