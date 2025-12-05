{
  description = "Frostflake: multi-host NixOS 25.11 + home-manager + nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nix-darwin,
    pre-commit-hooks,
    ...
  }: let
    inherit (nixpkgs) lib;
    frostflakeRoot = ./.;
    frostflakeUser = import ./lib/frostflake/user.nix;
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = fn:
      lib.genAttrs systems (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        frostflakePackages = import (frostflakeRoot + "/lib/frostflake/packages.nix") {inherit pkgs lib;};
      in
        fn {inherit system pkgs frostflakePackages;});
  in {
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    devShells = forAllSystems ({
      pkgs,
      system,
      frostflakePackages,
      ...
    }: {
      default = pkgs.mkShell {
        name = "frostflake";
        packages = frostflakePackages.devShell;
        shellHook = ''
          export NIX_CONFIG="experimental-features = nix-command flakes"
          echo "Loaded frostflake dev shell (${system}) for $USER"
        '';
      };
    });

    checks = forAllSystems ({system, ...}: {
      pre-commit = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          statix.enable = true;
          deadnix.enable = true;
        };
      };
    });

    nixosConfigurations = {
      Avalanche = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs frostflakeUser frostflakeRoot;};
        modules = [./hosts/avalanche/default.nix];
      };

      Aurora = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs frostflakeUser frostflakeRoot;};
        modules = [./hosts/aurora/default.nix];
      };

      Iceberg = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs frostflakeUser frostflakeRoot;};
        modules = [./hosts/iceberg/default.nix];
      };

      Hailstone = lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs frostflakeUser frostflakeRoot;};
        modules = [./hosts/hailstone/default.nix];
      };
    };

    darwinConfigurations = {
      Glacier = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs frostflakeUser frostflakeRoot;};
        modules = [./hosts/glacier/default.nix];
      };
    };
  };
}
