_: {
  virtualisation.oci-containers.containers.gpu-hot = {
    autoStart = true;
    image = "ghcr.io/psalias2006/gpu-hot:latest";
    ports = ["1312:1312"];
    environment = {
      NODE_NAME = "Avalanche";
    };
    extraOptions = [
      "--gpus=all"
      "--init"
      "--pid=host"
    ];
  };
}
