_: {
  systemd.tmpfiles.rules = [
    "d /var/lib/viniplay 0750 root root -"
    "d /var/lib/viniplay/data 0750 root root -"
    "d /var/lib/viniplay/dvr 0750 root root -"
  ];

  virtualisation.oci-containers.containers.viniplay = {
    image = "ardovini/viniplay:latest";
    autoStart = false; # Set true to enable on boot, or use systemctl enable/disable.
    ports = ["8998:8998"];
    volumes = [
      "/var/lib/viniplay/data:/data"
      "/var/lib/viniplay/dvr:/dvr"
    ];
  };
}
