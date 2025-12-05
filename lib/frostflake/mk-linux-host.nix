{lib}: {
  inputs,
  frostflakeRoot,
  frostflakeUser,
  homeModule,
  hostName,
  extraModules ? [],
  extraConfig ? {},
  ...
}: let
  inherit (lib) mkMerge;
  baseImports = [
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
  config = mkMerge [baseConfig extraConfig];
}
