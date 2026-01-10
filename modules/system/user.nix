{
  config,
  lib,
  pkgs,
  frostflakeUser,
  ...
}: let
  inherit (lib) mkDefault optionalAttrs optionals;
  user = frostflakeUser;
  shellPackage = user.shellPackage pkgs;
  groups = user.extraGroups or [];
  description = user.description or user.fullName or user.username;
  homeDir = user.linuxHome or "/home/${user.username}";
  securityPrefs = user.security or {};
  sshPrefs = securityPrefs.ssh or {};
  requireWebauthn = securityPrefs.requireWebauthn or true;
  sudoNeedsPassword = securityPrefs.sudoNeedsPassword or false;
  hardwareKeys = sshPrefs.hardwareKeys or [];
  softFallbackKeys = sshPrefs.softFallbackKeys or [];
  allowSoftFallback = sshPrefs.allowSoftFallback or false;
  combinedKeys =
    if hardwareKeys != []
    then hardwareKeys
    else optionals allowSoftFallback softFallbackKeys;
  webauthnConfig = config.frostflake.security.webauthn or {};
  exemptGroup =
    if (webauthnConfig.enable or true) && (webauthnConfig.allowUserOptOut or true)
    then webauthnConfig.exemptGroup or "frostflake-webauthn-exempt"
    else null;
  resolvedGroups = groups ++ optionals (exemptGroup != null && !requireWebauthn) [exemptGroup];
  managedHashedPassword = user.hashedPassword or null;
  managedHashedPasswordFile = user.hashedPasswordFile or null;
  hasManagedPassword = (managedHashedPassword != null) || (managedHashedPasswordFile != null);
in {
  users.users.${user.username} =
    {
      isNormalUser = true;
      inherit description;
      home = homeDir;
      shell = shellPackage;
      extraGroups = resolvedGroups;
      openssh.authorizedKeys.keys = combinedKeys;
    }
    // optionalAttrs (managedHashedPassword != null) {
      hashedPassword = managedHashedPassword;
    }
    // optionalAttrs (managedHashedPasswordFile != null) {
      hashedPasswordFile = managedHashedPasswordFile;
    };

  # Keep users mutable unless a managed password is supplied, so local password
  # changes persist instead of being reset on rebuild.
  users.mutableUsers = mkDefault (!hasManagedPassword);

  security.sudo = {
    enable = true;
    wheelNeedsPassword = sudoNeedsPassword;
  };
}
