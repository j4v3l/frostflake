{
  frostflakeDesktop ? {
    enable = true;
    type = "gnome";
  },
}: {
  lib,
  pkgs,
  options,
  ...
}: let
  inherit (lib) hasAttrByPath mkDefault mkIf mkMerge setAttrByPath;

  cosmicPortals =
    if pkgs ? xdg-desktop-portal-cosmic
    then [pkgs.xdg-desktop-portal-cosmic]
    else [pkgs.xdg-desktop-portal-gtk];

  hyprPortal =
    pkgs.xdg-desktop-portal-hyprland
    or (pkgs.xdg-desktop-portal-wlr or pkgs.xdg-desktop-portal-gtk);

  kdePortal =
    pkgs.xdg-desktop-portal-kde
    or (
      if (pkgs ? kdePackages) && (pkgs.kdePackages ? xdg-desktop-portal-kde)
      then pkgs.kdePackages.xdg-desktop-portal-kde
      else pkgs.xdg-desktop-portal-gtk
    );

  desktopManagerPathFor = profile:
    if hasAttrByPath ["services" "desktopManager" profile] options
    then ["services" "desktopManager"]
    else ["services" "xserver" "desktopManager"];

  mkDesktopEnable = profile: setAttrByPath (desktopManagerPathFor profile ++ [profile "enable"]) true;

  displayManagerPathFor = attrPath:
    if hasAttrByPath (["services" "displayManager"] ++ attrPath) options
    then ["services" "displayManager"]
    else ["services" "xserver" "displayManager"];

  setDisplayAttr = attrPath: value: setAttrByPath (displayManagerPathFor attrPath ++ attrPath) value;

  desktopProfiles = {
    gnome = mkMerge [
      (mkDesktopEnable "gnome")
      (setDisplayAttr ["gdm" "enable"] true)
      (setDisplayAttr ["gdm" "wayland"] true)
      {
        programs.dconf.enable = true;
        services.gnome.gnome-keyring.enable = true;
        environment.systemPackages = with pkgs; [
          gnomeExtensions.appindicator
          gnomeExtensions.blur-my-shell
          gnome-tweaks
        ];
        xdg.portal.extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
      }
    ];

    kde = mkMerge [
      (mkDesktopEnable "plasma6")
      (setDisplayAttr ["sddm" "enable"] true)
      (setDisplayAttr ["sddm" "wayland" "enable"] true)
      {
        environment.systemPackages = with pkgs; [
          kdePackages.kdeconnect-kde
        ];
        xdg.portal.extraPortals = [kdePortal];
      }
    ];

    xfce = mkMerge [
      (mkDesktopEnable "xfce")
      (setDisplayAttr ["lightdm" "enable"] true)
      {
        environment.systemPackages = with pkgs; [
          xfce.xfce4-whiskermenu-plugin
          xfce.xfce4-power-manager
        ];
        xdg.portal.extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      }
    ];

    cosmic = mkMerge [
      (mkDesktopEnable "cosmic")
      (setDisplayAttr ["cosmic-greeter" "enable"] true)
      {
        xdg.portal.extraPortals = cosmicPortals;
      }
    ];

    hyprland = mkMerge [
      {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
        };

        services = {
          seatd.enable = true;
          greetd = {
            enable = true;
            settings.default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd Hyprland";
              user = "greeter";
            };
          };
        };

        # Force X11 off for Hyprland to avoid conflicting mkDefault values from commonConfig.
        services.xserver.enable = lib.mkForce false;

        security = {
          polkit.enable = true;
          pam.services.hyprlock = {};
        };

        xdg.portal = {
          xdgOpenUsePortal = true;
          extraPortals = [hyprPortal pkgs.xdg-desktop-portal-gtk];
          config = {
            common.default = ["hyprland"];
            hyprland.default = ["hyprland" "gtk"];
          };
        };

        environment.variables = {
          NIXOS_OZONE_WL = "1";
        };

        environment.systemPackages = with pkgs; [
          brightnessctl
          cliphist
          dunst
          grim
          grimblast
          hypridle
          hyprland
          hyprlock
          hyprpaper
          kitty
          mako
          networkmanagerapplet
          pavucontrol
          polkit_gnome
          rofi
          slurp
          swaybg
          swappy
          waybar
          wf-recorder
          wl-clipboard
          wlogout
          wireplumber
        ];
      }
    ];
  };

  commonConfig = mkMerge [
    {
      services.xserver = {
        enable = mkDefault true;
        videoDrivers = mkDefault ["modesetting"];
        xkb.layout = "us";
      };
      services.flatpak.enable = true;
      xdg.portal.enable = true;
    }
    (setDisplayAttr ["autoLogin"] {
      enable = mkDefault false;
    })
  ];

  selectedProfile = frostflakeDesktop.type;
  hasProfile = builtins.hasAttr selectedProfile desktopProfiles;
  selectedConfig =
    if hasProfile
    then desktopProfiles.${selectedProfile}
    else throw ''Unsupported desktop type "${selectedProfile}". Expected one of: ${builtins.concatStringsSep ", " (builtins.attrNames desktopProfiles)}'';
in {
  config = mkIf frostflakeDesktop.enable (mkMerge [commonConfig selectedConfig]);
}
