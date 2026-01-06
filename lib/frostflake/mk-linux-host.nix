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
    (frostflakeRoot + "/modules/system/ai.nix")
    (frostflakeRoot + "/modules/system/linux-base.nix")
    (frostflakeRoot + "/modules/system/vpn.nix")
    (frostflakeRoot + "/modules/system/security/webauthn.nix")
    (frostflakeRoot + "/modules/system/secrets.nix")
    (frostflakeRoot + "/modules/system/user.nix")
    (frostflakeRoot + "/modules/hardware/gpu.nix")
    inputs."home-manager".nixosModules."home-manager"
    inputs."sops-nix".nixosModules.sops
  ];
  baseConfig = {
    networking.hostName = hostName;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {inherit frostflakeUser frostflakeRoot inputs;};
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
