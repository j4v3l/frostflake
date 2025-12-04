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

  time.timeZone = lib.mkDefault "Etc/UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

  networking.networkmanager.enable = true;

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;

  services = {
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
    };
    ollama.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
  };

  programs.zsh.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  services.dockerManager.enable = lib.mkDefault true;

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
