{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.vmManager;

  diskType = types.submodule (_: {
    options = {
      path = mkOption {
        type = types.either types.path types.str;
        description = "Absolute path to the disk image or block device.";
      };
      format = mkOption {
        type = types.enum ["qcow2" "raw"];
        default = "qcow2";
        description = "Disk format advertised to libvirt.";
      };
      device = mkOption {
        type = types.enum ["disk" "cdrom"];
        default = "disk";
        description = "Device type passed to libvirt.";
      };
      bus = mkOption {
        type = types.enum ["virtio" "sata" "scsi" "ide"];
        default = "virtio";
        description = "Bus type for the disk.";
      };
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional explicit target device name (e.g. vda).";
      };
      cache = mkOption {
        type = types.enum ["none" "writeback" "writethrough" "unsafe"];
        default = "none";
        description = "Cache mode for the disk driver.";
      };
      readOnly = mkEnableOption "readonly presentation of the disk";
      bootOrder = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Optional explicit boot priority (smaller numbers boot first).";
      };
    };
  });

  networkType = types.submodule (_: {
    options = {
      type = mkOption {
        type = types.enum ["network" "bridge" "direct"];
        default = "network";
        description = "How the interface connects to the host.";
      };
      source = mkOption {
        type = types.str;
        default = "default";
        description = "Network name, bridge device, or interface depending on type.";
      };
      model = mkOption {
        type = types.enum ["virtio" "e1000" "rtl8139" "vmxnet3"];
        default = "virtio";
        description = "Device model exposed to the guest.";
      };
      macAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Static MAC address (optional).";
      };
    };
  });

  vmType = types.submodule (_: {
    options = {
      enable = mkEnableOption "building this VM";

      description = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional free-form description.";
      };

      arch = mkOption {
        type = types.enum ["x86_64" "aarch64"];
        default = "x86_64";
        description = "Guest architecture.";
      };

      machine = mkOption {
        type = types.str;
        default = "pc-q35-9.0";
        description = "QEMU machine type string.";
      };

      memoryMiB = mkOption {
        type = types.int;
        default = 4096;
        description = "Guest memory in MiB.";
      };

      vcpus = mkOption {
        type = types.int;
        default = 4;
        description = "Number of virtual CPUs.";
      };

      autostart = mkEnableOption "starting the VM automatically when libvirtd comes up";

      uefi = mkEnableOption "UEFI/OVMF firmware" // {default = true;};

      tpm2 = mkEnableOption "attaching a software TPM (requires swtpm support)";

      spice = {
        enable = mkEnableOption "SPICE graphics" // {default = true;};
        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address SPICE listens on.";
        };
      };

      disks = mkOption {
        type = types.listOf diskType;
        default = [];
        description = "Disk images exposed to the guest.";
      };

      networks = mkOption {
        type = types.listOf networkType;
        default = [{}];
        description = "Network interfaces exposed to the guest.";
      };

      extraDevicesXML = mkOption {
        type = types.lines;
        default = "";
        description = "Raw XML appended inside <devices>.";
      };

      extraDomainXML = mkOption {
        type = types.lines;
        default = "";
        description = "Raw XML appended before </domain>.";
      };
    };
  });

  activeVMs = filterAttrs (_: vm: vm.enable) cfg.virtualMachines;

  alphabet = stringToCharacters "abcdefghijklmnopqrstuvwxyz";

  nthLetter = idx: let
    lastIdx = (stringLength "abcdefghijklmnopqrstuvwxyz") - 1;
  in
    builtins.elemAt alphabet (min idx lastIdx);

  defaultDiskTarget = idx: device: let
    prefix =
      if device == "disk"
      then "vd"
      else "sd";
  in "${prefix}${nthLetter idx}";

  mkDiskXml = idx: disk: let
    targetDev =
      if disk.target != null
      then disk.target
      else defaultDiskTarget idx disk.device;
    filePath = escapeXML (toString disk.path);
  in ''
    <disk type='file' device='${disk.device}'>
      <driver name='qemu' type='${disk.format}' cache='${disk.cache}'/>
      <source file='${filePath}'/>
      <target dev='${targetDev}' bus='${disk.bus}'/>
      ${optionalString disk.readOnly "<readonly/>"}
      ${optionalString (disk.bootOrder != null) "<boot order='${toString disk.bootOrder}'/>"}
    </disk>
  '';

  mkNetXml = net: let
    sourceAttr =
      if net.type == "bridge"
      then "bridge='${net.source}'"
      else if net.type == "direct"
      then "dev='${net.source}' mode='bridge'"
      else "network='${net.source}'";
  in ''
    <interface type='${net.type}'>
      <source ${sourceAttr}/>
      <model type='${net.model}'/>
      ${optionalString (net.macAddress != null) "<mac address='${net.macAddress}'/>"}
    </interface>
  '';

  mkSpiceXml = vm:
    if vm.spice.enable
    then ''
      <graphics type='spice' autoport='yes' listen='${vm.spice.listenAddress}'/>
      <video>
        <model type='virtio' heads='1' primary='yes'/>
      </video>
      <channel type='spicevmc'>
        <target type='virtio' name='com.redhat.spice.0'/>
      </channel>
      <input type='tablet' bus='usb'/>
    ''
    else ''
      <graphics type='vnc' autoport='yes' listen='127.0.0.1'/>
      <video>
        <model type='virtio'/>
      </video>
    '';

  mkTpmXml = vm:
    optionalString vm.tpm2 ''
      <tpm model='tpm-crb'>
        <backend type='emulator' version='2.0'/>
      </tpm>
    '';

  ovmfCode = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
  nvramPath = name: "/var/lib/libvirt/qemu/nvram/${name}.fd";

  mkOsXml = name: vm: let
    base = ''
      <type arch='${vm.arch}' machine='${vm.machine}'>hvm</type>
    '';
  in
    if vm.uefi
    then ''
      ${base}
      <loader readonly='yes' type='pflash'>${ovmfCode}</loader>
      <nvram>${nvramPath name}</nvram>
    ''
    else base;

  mkVmXml = name: vm: let
    diskXml = concatStringsSep "" (imap1 (idx: disk: mkDiskXml (idx - 1) disk) vm.disks);
    netXml = concatStringsSep "" (map mkNetXml vm.networks);
  in
    pkgs.writeText "${name}-domain.xml" ''
      <domain type='kvm'>
        <name>${name}</name>
        ${optionalString (vm.description != null) "<description>${escapeXML vm.description}</description>"}
        <memory unit='MiB'>${toString vm.memoryMiB}</memory>
        <currentMemory unit='MiB'>${toString vm.memoryMiB}</currentMemory>
        <vcpu placement='static'>${toString vm.vcpus}</vcpu>
        <os>
          ${mkOsXml name vm}
        </os>
        <features>
          <acpi/>
          <apic/>
          <hyperv>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
          </hyperv>
        </features>
        <cpu mode='host-passthrough'/>
        <clock offset='utc'/>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>restart</on_crash>
        <devices>
          ${diskXml}
          ${netXml}
          ${mkSpiceXml vm}
          <console type='pty'/>
          <rng model='virtio'>
            <backend model='random'>/dev/urandom</backend>
          </rng>
          ${mkTpmXml vm}
          ${vm.extraDevicesXML}
        </devices>
        ${vm.extraDomainXML}
      </domain>
    '';

  vmXmlFiles =
    mapAttrsToList (name: vm: {
      inherit name;
      file = mkVmXml name vm;
      inherit (vm) autostart;
    })
    activeVMs;

  mkEtcEntries =
    map (entry: {
      name = "libvirt/qemu/${entry.name}.xml";
      value = {
        source = entry.file;
        mode = "0600";
      };
    })
    vmXmlFiles;

  mkAutostartEntries = map (entry: {
    name = "libvirt/qemu/autostart/${entry.name}.xml";
    value = {
      source = entry.file;
      mode = "0600";
    };
  }) (filter (entry: entry.autostart) vmXmlFiles);

  mkNvramRules =
    mapAttrsToList (name: _: ''C /var/lib/libvirt/qemu/nvram/${name}.fd 0600 root root - ${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd'')
    (filterAttrs (_: vm: vm.uefi) activeVMs);

  etcAssignments = map (entry: {"${entry.name}" = entry.value;}) (mkEtcEntries ++ mkAutostartEntries);

  tmpfilesRules = let
    nvramRules = mkNvramRules;
    baseDirRule = optional (nvramRules != []) "d /var/lib/libvirt/qemu/nvram 0755 root root -";
  in
    baseDirRule ++ nvramRules;
in {
  options.services.vmManager = {
    enable = mkEnableOption "libvirt-backed VM definitions";

    packages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [virt-manager virt-viewer spice-gtk virtiofsd];
      example = literalExpression "with pkgs; [ virt-manager virt-viewer ]";
      description = "Extra packages installed on the host for VM management.";
    };

    qemuPackage = mkOption {
      type = types.package;
      default = pkgs.qemu_kvm;
      description = "QEMU build used by libvirtd.";
    };

    enableSwtpm = mkEnableOption "software TPM device support" // {default = true;};

    virtualMachines = mkOption {
      type = types.attrsOf vmType;
      default = {};
      description = "Declarative set of libvirt virtual machines.";
    };
  };

  config = mkIf cfg.enable (
    let
      etcSet =
        if etcAssignments == []
        then {}
        else mkMerge etcAssignments;
    in {
      assertions =
        mapAttrsToList (
          name: vm: {
            assertion = (length (filter (disk: disk.device == "disk") vm.disks)) > 0;
            message = "VM '${name}' must have at least one disk device of type 'disk'.";
          }
        )
        activeVMs;

      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = cfg.qemuPackage;
          runAsRoot = true;
          verbatimConfig = ''
            namespaces = []
          '';
          swtpm = mkIf cfg.enableSwtpm {
            enable = true;
            package = pkgs.swtpm;
          };
        };
      };

      environment.systemPackages = cfg.packages;

      environment.etc = etcSet;

      systemd.tmpfiles.rules = mkAfter tmpfilesRules;
    }
  );
}
