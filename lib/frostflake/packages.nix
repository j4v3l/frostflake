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
    bat
    direnv
    eza
    git
    glances
    nix-direnv
    pciutils
    ripgrep
    tree
    unzip
    vim
    wget
    lazygit
    tmux
  ];

  homeCliBase = with pkgs; [
    alejandra
    bat
    btop
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
  ];

  lintingTools = with pkgs; [
    alejandra
    deadnix
    statix
  ];

  shellTools = with pkgs; [
    direnv
    nix-direnv
    git
    pre-commit
  ];

  desktopApps =
    if pkgs.stdenv.hostPlatform.isx86_64
    then
      with pkgs; [
        brave
        code-cursor
        lmstudio
        ollama
        vscode
      ]
    else [];

  homeDesktopLinux =
    if pkgs.stdenv.hostPlatform.isx86_64
    then
      with pkgs; [
        brave
        code-cursor
        gnome-terminal
        lmstudio
        ollama
        vscode
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

  home = {
    common = unique homeCommon;
    linuxDesktop = unique homeDesktopLinux;
    darwinExtra = darwinExtras;
  };

  devShell = unique devShellPackages;
}
