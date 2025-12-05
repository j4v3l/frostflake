{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];

  time = {
    timeZone = lib.mkDefault "Etc/UTC";
    hardwareClockInLocalTime = lib.mkDefault true;
  };
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

  networking.networkmanager.enable = true;

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;

  security.rtkit.enable = true;

  services = {
    udev.extraRules = ''
      # Stable alias for the Maono PD400X USB audio interface
      ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="352f", ATTRS{idProduct}=="0100", ATTRS{product}=="PD400X Podcast Microphone", SYMLINK+="snd/by-id/PD400X"
      # Ensure MCU serial adapters are writable for dialout users
      KERNEL=="ttyACM[0-9]*", MODE:="0660", GROUP:="dialout"
      KERNEL=="ttyUSB[0-9]*", MODE:="0660", GROUP:="dialout"
    '';
    fwupd.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        LoginGraceTime = "30s";
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
        MaxAuthTries = 3;
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig = {
        pipewire."context.properties" = {
          default = {
            clock = {
              rate = 48000;
              allowed-rates = [48000 96000];
              quantum = 256;
              min-quantum = 32;
              max-quantum = 2048;
            };
          };
          resample.quality = 10;
        };
        "pipewire-pulse"."context.properties" = {
          "resample.quality" = 10;
        };
        "pipewire-pulse"."stream.properties" = {
          "node.latency" = "64/48000";
          "resample.quality" = 10;
        };
      };
    };
    ollama.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
    dockerManager.enable = lib.mkDefault true;
  };

  programs.zsh.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  environment.systemPackages = with pkgs;
    [
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
      # MCU / embedded tooling
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
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      brave
      code-cursor
      lmstudio
      ollama
      vscode
    ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
  ];
}
