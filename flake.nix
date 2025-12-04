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
    user = "jager";
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = fn:
      lib.genAttrs systems (system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
        fn {inherit system pkgs;});
  in {
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    devShells = forAllSystems ({
      pkgs,
      system,
      ...
    }: {
      default = pkgs.mkShell {
        name = "frostflake";
        packages = with pkgs; [alejandra statix deadnix direnv nix-direnv git pre-commit];
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
        specialArgs = {inherit inputs user;};
        modules = [./hosts/avalanche/default.nix];
      };

      Aurora = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs user;};
        modules = [./hosts/aurora/default.nix];
      };

      Iceberg = lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs user;};
        modules = [./hosts/iceberg/default.nix];
      };
    };

    darwinConfigurations = {
      Glacier = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs user;};
        modules = [./hosts/glacier/default.nix];
      };
    };
  };
}
