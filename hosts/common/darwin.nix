{
  config,
  lib,
  pkgs,
  ...
}: {
  services.nix-daemon.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    bat
    direnv
    eza
    fd
    git
    glances
    nix-direnv
    neovim
    ripgrep
    starship
    tree
    unzip
    glances
    duf
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
    casks =
      [
        "brave-browser"
        "visual-studio-code"
      ]
      ++ lib.optionals (
        config.frostflake.ai.enable && config.frostflake.ai.packages.enable
      )
      config.frostflake.ai.packages.darwinCasks;
  };

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;
}
