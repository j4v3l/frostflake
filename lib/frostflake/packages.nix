{
  pkgs,
  lib,
}: let
  inherit (lib.lists) unique;
  embeddedTools = with pkgs; [
    arduino-cli
    avrdude
    dfu-util
    esptool
    espflash
    espup
    openocd
    picocom
    platformio-core
    python3Packages.pyserial
    rustup
  ];

  systemCliBase = with pkgs; [
    age
    bat
    direnv
    eza
    git
    glances
    age-plugin-yubikey
    nix-direnv
    pciutils
    ripgrep
    sops
    tree
    unzip
    vim
    wget
    lazygit
    tmux
  ];

  homeCliBase = with pkgs; [
    age
    age-plugin-yubikey
    alejandra
    bat
    btop
    deadnix
    direnv
    eza
    fd
    glances
    nil
    nixd
    neovim
    ripgrep
    sops
    starship
    statix
    uv
    ruff
    tree
  ];

  lintingTools = with pkgs; [
    alejandra
    deadnix
    statix
  ];

  shellTools = with pkgs; [
    age
    direnv
    nix-direnv
    git
    sops
    pre-commit
  ];

  desktopApps =
    if pkgs.stdenv.hostPlatform.isx86_64
    then
      with pkgs; [
        brave
        vscode
      ]
    else [];

  homeDesktopLinux =
    if pkgs.stdenv.hostPlatform.isx86_64
    then
      with pkgs; [
        brave
        gnome-terminal
        vscode
      ]
    else [];

  aiDesktopApps =
    if pkgs.stdenv.hostPlatform.isx86_64
    then
      with pkgs; [
        code-cursor
        lmstudio
        ollama
      ]
    else [];

  darwinExtras =
    if pkgs.stdenv.hostPlatform.isDarwin
    then with pkgs; [iterm2]
    else [];

  devShellPackages = lintingTools ++ shellTools ++ embeddedTools;
  systemCli = systemCliBase ++ embeddedTools;
  homeCommon = homeCliBase ++ embeddedTools;
in {
  system = {
    cli = unique systemCli;
    desktop = desktopApps;
  };

  ai = {
    system = aiDesktopApps;
    home = aiDesktopApps;
    darwinCasks = [
      "cursor"
      "lm-studio"
      "ollama"
    ];
  };

  home = {
    common = unique homeCommon;
    linuxDesktop = unique homeDesktopLinux;
    darwinExtra = darwinExtras;
  };

  devShell = unique devShellPackages;
}
