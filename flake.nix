{
  description = "Frostflake: multi-host NixOS 25.11 + home-manager + nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      frostflakePackages,
      ...
    }: let
      basePackages = frostflakePackages.devShell;
      shellHook = ''
        export NIX_CONFIG="experimental-features = nix-command flakes"
      '';
      mkDevShell = {
        name,
        extraPackages ? [],
      }:
        pkgs.mkShell {
          inherit name shellHook;
          packages = basePackages ++ extraPackages;
        };
      cDebugger =
        if pkgs.stdenv.hostPlatform.isDarwin
        then pkgs.lldb
        else pkgs.gdb;
      goPackages = with pkgs; [
        go
        gopls
        golangci-lint
      ];
      rustPackages = with pkgs; [
        rust-analyzer
      ];
      pythonPackages = with pkgs; [
        python3
        uv
        ruff
      ];
      cPackages =
        (with pkgs; [
          clang
          cmake
          gnumake
          pkg-config
        ])
        ++ [cDebugger];
      luaPackages = with pkgs; [
        lua
        lua-language-server
        luarocks
      ];
    in {
      default = mkDevShell {name = "frostflake";};
      golang = mkDevShell {
        name = "frostflake-golang";
        extraPackages = goPackages;
      };
      rust = mkDevShell {
        name = "frostflake-rust";
        extraPackages = rustPackages;
      };
      python = mkDevShell {
        name = "frostflake-python";
        extraPackages = pythonPackages;
      };
      c = mkDevShell {
        name = "frostflake-c";
        extraPackages = cPackages;
      };
      lua = mkDevShell {
        name = "frostflake-lua";
        extraPackages = luaPackages;
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
