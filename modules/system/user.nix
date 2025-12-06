{
  config,
  lib,
  pkgs,
  frostflakeUser,
  ...
}: let
  inherit (lib) optionals;
  user = frostflakeUser;
  shellPackage = user.shellPackage pkgs;
  groups = user.extraGroups or [];
  description = user.description or user.fullName or user.username;
  homeDir = user.linuxHome or "/home/${user.username}";
  securityPrefs = user.security or {};
  sshPrefs = securityPrefs.ssh or {};
  requireWebauthn = securityPrefs.requireWebauthn or true;
  hardwareKeys = sshPrefs.hardwareKeys or [];
  softFallbackKeys = sshPrefs.softFallbackKeys or [];
  allowSoftFallback = sshPrefs.allowSoftFallback or false;
  combinedKeys = hardwareKeys ++ optionals allowSoftFallback softFallbackKeys;
  webauthnConfig = config.frostflake.security.webauthn or {};
  exemptGroup =
    if (webauthnConfig.enable or true) && (webauthnConfig.allowUserOptOut or true)
    then webauthnConfig.exemptGroup or "frostflake-webauthn-exempt"
    else null;
  resolvedGroups =
    groups
    ++ optionals (exemptGroup != null && !requireWebauthn) [exemptGroup];
in {
  users.users.${user.username} = {
    isNormalUser = true;
    inherit description;
    home = homeDir;
    shell = shellPackage;
    extraGroups = resolvedGroups;
    openssh.authorizedKeys.keys = combinedKeys;
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
