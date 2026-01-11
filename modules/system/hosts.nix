{
  config,
  lib,
  ...
}: let
  inherit (lib) mkAfter mkEnableOption mkIf mkOption optionals types;
  joinWith = lib.concatStringsSep;
  cfg = config.frostflake.network.hosts;
  entryType = types.submodule {
    options = {
      enable = mkEnableOption "Enable this /etc/hosts entry" // {default = true;};
      ip = mkOption {
        type = types.str;
        description = "IP address for the host entry.";
      };
      hostnames = mkOption {
        type = types.listOf types.str;
        description = "One or more hostnames for the IP.";
      };
    };
  };
  enabledEntries = builtins.filter (entry: entry.enable) cfg.entries;
  entryLines =
    map (entry: "${entry.ip} ${joinWith " " entry.hostnames}") enabledEntries;
  extraLines = optionals (cfg.extraLines != "") [cfg.extraLines];
in {
  options.frostflake.network.hosts = {
    enable = mkEnableOption "Managed /etc/hosts entries" // {default = true;};
    entries = mkOption {
      type = types.listOf entryType;
      default = [];
      description = "Declarative /etc/hosts entries shared across hosts.";
    };
    extraLines = mkOption {
      type = types.lines;
      default = "";
      description = "Raw /etc/hosts lines appended after declarative entries.";
    };
  };

  config = mkIf cfg.enable {
    networking.extraHosts = mkAfter (joinWith "\n" (entryLines ++ extraLines));
  };
}
