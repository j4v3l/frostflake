{lib}: {
  inputs,
  frostflakeRoot,
  frostflakeUser,
  homeModule,
  hostName,
  desktopProfile ? "gnome",
  desktopEnable ? true,
  extraModules ? [],
  extraConfig ? {},
  ...
}: let
  inherit (lib) mkMerge;
  desktopModule = import (frostflakeRoot + "/modules/system/desktop.nix") {
    frostflakeDesktop = {
      enable = desktopEnable;
      type = desktopProfile;
    };
  };
  baseImports = [
    desktopModule
    (frostflakeRoot + "/modules/system/linux-base.nix")
    (frostflakeRoot + "/modules/system/user.nix")
    (frostflakeRoot + "/modules/hardware/gpu.nix")
    inputs."home-manager".nixosModules."home-manager"
  ];
  baseConfig = {
    networking.hostName = hostName;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit frostflakeUser frostflakeRoot;};
      users.${frostflakeUser.username} = homeModule;
    };
  };
in {
  imports = baseImports ++ extraModules;
  config = mkMerge [
    baseConfig
    extraConfig
  ];
}
