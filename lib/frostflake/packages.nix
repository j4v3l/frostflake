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

  # nordvpn exists only on x86_64-linux; guard to keep other systems evaluable.
  nordvpnPkg =
    if pkgs ? nordvpn
    then [pkgs.nordvpn]
    else [];

  systemCliBase = with pkgs;
    [
      age
      bat
      direnv
      eza
      nh
      tailscale
      wireguard-tools
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
    ]
    ++ nordvpnPkg;

  homeCliBase = with pkgs;
    [
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
      ghostty
      kitty
      go
      nil
      nixd
      nh
      neovim
      ripgrep
      sops
      starship
      statix
      uv
      ruff
      tree
    ]
    ++ nordvpnPkg;

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
    nh
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
      (with pkgs; [
        brave
        blackbox-terminal
        gnome-terminal
        tailscale
        wireguard-tools
        vscode
      ])
      ++ nordvpnPkg
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
