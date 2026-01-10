{
  frostflakeDesktop ? {
    enable = true;
    type = "gnome";
  },
}: {
  config,
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
  };

  commonConfig = mkMerge [
    {
      services.xserver = {
        enable = true;
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
  fprintPamServiceFor = {
    gnome = "gdm-password";
    kde = "sddm";
    xfce = "lightdm";
    cosmic = "cosmic-greeter";
  };
  fprintPamConfig = mkIf (config.services.fprintd.enable && builtins.hasAttr selectedProfile fprintPamServiceFor) {
    security.pam.services.${fprintPamServiceFor.${selectedProfile}}.fprintAuth = mkDefault true;
  };
  selectedConfig =
    if hasProfile
    then desktopProfiles.${selectedProfile}
    else throw ''Unsupported desktop type "${selectedProfile}". Expected one of: ${builtins.concatStringsSep ", " (builtins.attrNames desktopProfiles)}'';
in {
  config = mkIf frostflakeDesktop.enable (mkMerge [commonConfig selectedConfig fprintPamConfig]);
}
