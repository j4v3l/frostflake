_: {
  virtualisation.oci-containers.containers.gpu-hot = {
    autoStart = true;
    image = "ghcr.io/psalias2006/gpu-hot:latest";
    ports = ["1312:1312"];
    environment = {
      NODE_NAME = "Avalanche";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,utility,video,graphics";
    };
    extraOptions = [
      "--runtime=nvidia"
      "--gpus=all"
      "--init"
      "--pid=host"
    ];
  };
}
