{
  pkgs,
  lib,
}: let
  inherit (lib.lists) unique;

  lightctl = pkgs.writeShellScriptBin "lightctl" ''
    case "$1" in
    up)
      ${pkgs.brightnessctl}/bin/brightnessctl -q s "$2"%+
      ;;
    down)
      ${pkgs.brightnessctl}/bin/brightnessctl -q s "$2"%-
      ;;
    esac

    brightness_percentage=$((($(${pkgs.brightnessctl}/bin/brightnessctl g) * 100) / $(${pkgs.brightnessctl}/bin/brightnessctl m)))
    ${pkgs.libnotify}/bin/notify-send -u normal -a "LIGHTCTL" "Brightness: $brightness_percentage%" \
      -h string:x-canonical-private-synchronous:lightctl \
      -h int:value:"$brightness_percentage" \
      -i display-brightness-symbolic
  '';

  networkctlScript = pkgs.writeShellScriptBin "networkctl" ''
    toggle_network() {
      wifi_state="$(${pkgs.util-linux}/bin/rfkill list wifi | grep -i 'Soft blocked: yes' > /dev/null && echo "off" || echo "on")"
      bluetooth_state="$(${pkgs.util-linux}/bin/rfkill list bluetooth | grep -i 'Soft blocked: yes' > /dev/null && echo "off" || echo "on")"

      if [ "$wifi_state" = "on" ] || [ "$bluetooth_state" = "on" ]; then
        ${pkgs.util-linux}/bin/rfkill block wifi
        ${pkgs.util-linux}/bin/rfkill block bluetooth
        ${pkgs.libnotify}/bin/notify-send -u normal -a "NETWORKCTL" "Airplane Mode Enabled" "Wi-Fi and Bluetooth disabled" -i airplane-mode-symbolic
      else
        ${pkgs.util-linux}/bin/rfkill unblock wifi
        ${pkgs.util-linux}/bin/rfkill unblock bluetooth
        ${pkgs.libnotify}/bin/notify-send -u normal -a "NETWORKCTL" "Airplane Mode Disabled" "Wi-Fi and Bluetooth enabled" -i airplane-mode-disabled-symbolic
      fi
    }

    case "$1" in
      toggle-network)
        toggle_network
        ;;
    esac
  '';

  volumectl = pkgs.writeShellScriptBin "volumectl" ''
    case "$1" in
    up)
      ${pkgs.wireplumber}/bin/wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ "$2%+"
      ;;
    down)
      ${pkgs.wireplumber}/bin/wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ "$2%-"
      ;;
    toggle-mute)
      ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      ;;
    toggle-mic-mute)
      ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      ;;
    esac

    volume_percentage="$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')"
    ${pkgs.libnotify}/bin/notify-send -u normal -a "VOLUMECTL" "Volume: $volume_percentage%" \
      -h string:x-canonical-private-synchronous:volumectl \
      -h int:value:"$volume_percentage" \
      -i audio-volume-high-symbolic

    ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -i audio-volume-change -d "volumectl"
  '';

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
        gnome-terminal
        tailscale
        wireguard-tools
        vscode
      ])
      ++ nordvpnPkg
    else [];

  hyprlandSystem = with pkgs; [
    grim
    grimblast
    hypridle
    hyprland
    hyprlock
    hyprpaper
    kitty
    lightctl
    networkctlScript
    volumectl
    brightnessctl
    cliphist
    dunst
    polkit_gnome
    wireplumber
    mako
    networkmanagerapplet
    pavucontrol
    rofi-wayland
    slurp
    swaybg
    swappy
    wf-recorder
    waybar
    wl-clipboard
    wlogout
  ];

  hyprlandHome = with pkgs; [
    grim
    hypridle
    hyprlock
    hyprpaper
    lightctl
    networkctlScript
    volumectl
    brightnessctl
    cliphist
    dunst
    polkit_gnome
    wireplumber
    mako
    networkmanagerapplet
    pavucontrol
    rofi-wayland
    slurp
    swaybg
    swappy
    wf-recorder
    waybar
    wl-clipboard
    wlogout
  ];

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
    hyprland = unique hyprlandSystem;
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
    hyprland = unique hyprlandHome;
    darwinExtra = darwinExtras;
  };

  devShell = unique devShellPackages;
}
