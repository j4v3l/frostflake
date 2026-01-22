# MicroVMs

MicroVM support now lives inside the flake so every host configuration can opt in. `lib/frostflake/mk-linux-host.nix` imports `microvm.nixosModules.host` when the `microvm` flake input exists and `modules/system/microvm-defaults.nix` keeps the host module disabled by default. The Linux hosts ship with helper modules (e.g., `hosts/avalanche/microvms.nix`) that can be plugged in when you are ready; until then the host module stays disabled because those helpers are not imported. Enable it on a host the same way we do for `hosts/avalanche`, `hosts/aurora`, `hosts/iceberg`, or `hosts/hailstone` once you pick a host:

```nix
let
  jagerPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCsQ4NNDuuAj/NLrC9yXVoGRNU5DRTEqC2ybN+Y9Qjf jager@Javels-MacBook-Pro.local";
  microvmModule = import ./microvms.nix { inherit jagerPublicKey frostflakeUser; };
in
mkLinuxHost {
  extraModules = [
    microvmModule
  ];
}
```

The helper file `hosts/<host>/microvms.nix` mirrors the current `frostflake-builder` example: it turns on the host module, defines the VM, shares `/nix/store`, opens SSH for the main user and forwards port 3022, and ensures the VM autostarts. Linux hosts already ship with one next to their `default.nix` (see `avalanche`, `aurora`, `iceberg`, and `hailstone`), and they all reuse the shared key at `hosts/common/jager-public-key.nix`. Add another helper in the same style when you enable microvms on a new host.

### Running a MicroVM

Each declarative VM exposes a runner package. Run a MicroVM interactively with:

```bash
nix run .#nixosConfigurations.Avalanche.config.microvm.declaredRunner
```

Replace `Avalanche` if you enable the host module elsewhere. The same package is used by the systemd services that manage the guest (`microvm@<name>.service`, `microvm-virtiofsd@<name>.service`, etc.). Because the host module imports `microvm.nixosModules.host`, all hosts can declare `microvm.vms.<name>` and get the required helper scripts without adding the input manually.

### Convenience aliases

Every host that enables the host module defines a couple of shell aliases:

```text
microvm-run   # runs the host’s `microvm.declaredRunner`
microvm-shell # lists the configured MicroVMs so you can drop into the console
```

Those aliases reference whichever host you are currently logged into, so you don’t need to type the long `nix run` invocation directly.
