{
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
  homeDir =
    if isDarwin
    then "/Users/jager"
    else "/home/jager";
  flakePath = "~/Documents/Codes/frostflake";
  treeAlias = "eza --tree --icons=always";
in {
  home = {
    username = "jager";
    homeDirectory = homeDir;
    packages = with pkgs;
      [
        alejandra
        bat
        deadnix
        direnv
        eza
        fd
        glances
        neovim
        ripgrep
        starship
        statix
        tree
      ]
      ++ lib.optionals (!isDarwin) [
        brave
        code-cursor
        gnome-terminal
        lmstudio
        ollama
        vscode
      ];
    sessionVariables = {
      FLAKE = flakePath;
      EDITOR = "nvim";
      LESS = "-FRSX";
    };
    stateVersion = "24.11";
  };

  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      settings = {
        user.name = "j4v3l";
        user.email = "jj4v3l@gmail.com";
        init.defaultBranch = "master";
        pull.ff = "only";
        push.autoSetupRemote = true;
      };
    };
    starship.enable = true;
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 50000;
      history.path = "${homeDir}/.zsh_history";
      initContent = ''
        eval "$(direnv hook zsh)"
      '';
      shellAliases = lib.mkMerge [
        {
          ll = "eza -lh --icons=always";
          la = "eza -lha --icons=always";
          lt = treeAlias;
          tree = "${treeAlias} -L 3";
          gs = "git status -sb";
          ga = "git add";
          gp = "git push";
          gl = "git pull";
          nclean = "sudo nix-collect-garbage -d && nix store optimise";
          nfu = "nix flake update";
          nfmt = "alejandra .";
          ncheck = "statix check . && deadnix";
        }
        (lib.mkIf (!isDarwin) {
          nixup = "sudo nixos-rebuild switch --flake ${flakePath}#$(hostname)";
          nixboot = "sudo nixos-rebuild boot --flake ${flakePath}#$(hostname)";
          nixdry = "nixos-rebuild dry-activate --flake ${flakePath}#$(hostname)";
        })
      ];
    };
  };

  fonts.fontconfig.enable = lib.mkDefault (!isDarwin);
  xdg = {
    enable = lib.mkDefault (!isDarwin);
    configFile."starship.toml".source = ./starship.toml;
  };
}
