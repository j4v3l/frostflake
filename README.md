# Frostflake

Multi-host Nix flake for the Avalanche (desktop), Aurora (laptop), Iceberg (VM), and Glacier (macOS) systems. It targets NixOS 25.11 with a selectable Linux desktop stack (GNOME by default) plus nix-darwin + Home Manager on macOS.

## Layout

- `flake.nix` – exposes NixOS, nix-darwin, dev shells, and formatters.
- `hosts/` – per-host entry points. Linux machines share the same base + desktop module, Glacier imports the nix-darwin stack.
- `modules/` – reusable building blocks (`linux-base`, `desktop`, the GPU selector, the VM manager, and the user module).
- `home/` – Home Manager profiles (common + Linux/Darwin overlays) that supply zsh, starship, aliases, etc.
- `.envrc` / `.direnv/` – enables `direnv` (`use flake`) for automatic shells.
- `.pre-commit-config.yaml` – runs `alejandra`, `statix`, `deadnix`, and `nix flake check` before each commit.

## Host matrix

| Host      | Platform                 | GPU profile | Notes |
|-----------|--------------------------|-------------|-------|
| Avalanche | x86_64 desktop           | `nvidia`    | RTX 5070 Ti + CUDA acceleration for Ollama. |
| Aurora    | x86_64 laptop            | `intel`     | Laptop power tweaks (`tlp`, disabled `power-profiles-daemon`). |
| Iceberg   | x86_64 VM                | `vm`        | Guest additions (`qemuGuest`, `spice-vdagentd`). |
| Hailstone | aarch64 Raspberry Pi SBC | `none`      | Headless Pi node for lightweight Docker services + homelab sensors. |
| Glacier   | aarch64-darwin           | —           | nix-darwin + Homebrew apps (Brave, Cursor, LM Studio, Ollama, VS Code). |

Linux hosts mount `/` via `fileSystems."/"` (currently pointing at `/dev/disk/by-label/nixos`). Update the device/fsType per machine before rebuilding.

## Developer workflow

```sh
# 1. Allow direnv once so shells auto-load
$ direnv allow

# 2. Enter the dev shell manually (optional when direnv is active)
$ nix develop

# 3. Install the git hooks (run once per clone)
$ pre-commit install

# 4. Hack as usual, then lint/format
$ nix fmt
$ nix flake check   # also runs via pre-commit
```

The dev shell brings `alejandra`, `statix`, `deadnix`, `direnv`, `nix-direnv`, `git`, and `pre-commit`. Hooks enforce formatting/linting and fail the commit if anything is out of date.

## Deploying hosts

```sh
# Linux machines
$ sudo nixos-rebuild switch --flake .#Avalanche
$ sudo nixos-rebuild switch --flake .#Aurora
$ sudo nixos-rebuild switch --flake .#Iceberg

# macOS
$ darwin-rebuild switch --flake .#Glacier
```

For Glacier, nix-darwin handles CLI tooling, while GUI apps (Brave, Cursor, LM Studio, Ollama, VS Code) are installed via Homebrew casks declared in `hosts/common/darwin.nix`.

## GPU + acceleration controls

`modules/hardware/gpu.nix` exposes `hardware.gpu.profile = "nvidia" | "intel" | "vm" | "none"`. Each host imports the module and sets the profile, so swapping drivers is as simple as changing that string.

Ollama’s acceleration is configured per host (`services.ollama.acceleration`). Avalanche uses `"cuda"` to match the RTX 5070 Ti; other machines leave it `false` for CPU-only inference. There is no separate `ollama-cuda` package—just flip the acceleration mode if the GPU supports CUDA/ROCm/Vulkan.

## Desktop selection

`modules/system/desktop.nix` now reads its marching orders from the helper: every call to `mkLinuxHost` can pass `desktopProfile = "gnome" | "kde" | "xfce" | "cosmic" | "deepin"` (and optionally `desktopEnable = false` for headless nodes). The module wires up the right display manager + Wayland session for each DE, supplies the matching portals, and reuses the same base X11/Flatpak defaults.

```nix
mkLinuxHost {
	# …standard args…
	desktopProfile = "kde";   # Avalanche uses "gnome", Iceberg "xfce", etc.
	desktopEnable = true;      # `false` keeps Hailstone headless
}
```

Avalanche sticks with GNOME, Aurora requests KDE, Iceberg prefers XFCE, and Hailstone disables the stack entirely without having to touch the shared modules.

## Declarative libvirt VMs

`modules/system/vms.nix` enables a libvirt-backed VM manager that both Avalanche and Aurora import. Turn it on per host via:

```nix
services.vmManager = {
	enable = true;
	virtualMachines = {
		"win11-dev" = {
			description = "Windows preview box";
			memoryMiB = 8192;
			vcpus = 4;
			autostart = false;
			disks = [
				{ path = "/var/lib/libvirt/images/win11.qcow2"; format = "qcow2"; }
				{ path = "/var/lib/libvirt/iso/Win11.iso"; device = "cdrom"; format = "raw"; }
			];
			networks = [{ source = "default"; }];
		};
	};
};
```

Each VM can be toggled individually with `enable = true/false`, made to autostart, and configured for UEFI (default), TPM2, SPICE graphics, and multiple disks or NICs. The module drops the domain XML in `/etc/libvirt/qemu`, copies OVMF vars via tmpfiles, installs `virt-manager`/`virt-viewer`, and adds `jager` to the `libvirtd` group so the user can manage guests. Create or resize disk images with `qemu-img`, then start/stop guests via `virt-manager` or `virsh start <name>`.

## Home environment highlights

- Zsh with completions, autosuggestions, syntax highlighting, direnv hooks, and starship prompt (Nerdfonts are provisioned on both Linux and macOS).
- Aliases for modern dir tooling (`eza`, `tree`), Git helpers, and NixOS workflows (`nixup`, `nixboot`, `nixdry`, `nclean`, etc.).
- Common CLI packages: alejandra, direnv, eza, fd, ripgrep, glances, tree, starship, neovim, statix, deadnix, plus `rustup` so `cargo`/`rustc` are immediately available. Linux adds GUI apps (Brave, Cursor, LM Studio, Ollama, VS Code, GNOME Terminal); macOS installs the GUI set via Homebrew.

## Microcontroller / embedded support

- The dev shell (`nix develop`) now ships PlatformIO Core, Arduino CLI, esptool, **espflash**, **espup**, OpenOCD, dfu-util, picocom, and `pyserial`, so ESP32/Arduino workflows work out-of-the-box.
- The shared Home Manager profile installs the same tooling on both Linux and macOS, so `arduino-cli`, `pio`, `esptool.py`, `espflash`, and `espup` are always on `$PATH`.
- Linux hosts include the toolchain system-wide, enable `programs.avrdude`, and add the `jager` user to `dialout`, `uucp`, and `plugdev` for serial/USB access.
- Typical flow:
	1. `nix develop`
	2. `arduino-cli core install esp32:esp32`, `pio pkg install`, or `espup install-latest` for your board support package + ESP-IDF toolchains (Rust components onboard thanks to `rustup`).
	3. `pio run -t upload` or `arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32`.
- `picocom -b 115200 /dev/ttyUSB0` (or `screen`) is ready for serial monitoring; use `dfu-util`, `esptool.py`, or `espflash`/`espup` for low-level flashing and ESP-IDF management when PlatformIO isn’t in play.

## PD400X microphone

- The shared Linux base module now enables `rtkit` and forces PipeWire to run at 48 kHz with a high quality resampler and 64/48000 latency, which matches the PD400X spec and prevents the crunchy audio the mic produced at 44.1 kHz.
- A dedicated udev rule publishes `/dev/snd/by-id/PD400X`, so commands like `udevadm info --query=all --name=/dev/snd/by-id/PD400X` and `pw-cli list-objects Device | rg -n -A6 -B2 -i PD400X` always work on Avalanche and Aurora.
- To troubleshoot: (1) run `pw-top` and confirm the PD400X input stays locked at 48 kHz, (2) open `pavucontrol` or the GNOME sound panel to adjust mic gain (0–42 dB is exposed via the USB interface), and (3) double-check that no other USB hubs are dropping the device to USB 1.1 speeds.

## Customization checklist

- **Root disks** – update `fileSystems."/"` in each host to reflect the real device/UUID.
- **Drivers** – change `hardware.gpu.profile` (and, if needed, `services.ollama.acceleration`) to adopt a new GPU.
- **Desktop** – pass `desktopProfile = "gnome" | "kde" | "xfce" | "cosmic" | "deepin"` (or `desktopEnable = false`) to `mkLinuxHost` when defining a host to choose the environment.
- **Packages** – extend `modules/system/linux-base.nix` or the Home Manager profiles for shared tooling.
- **Secrets** – add host-specific modules or overlays for secrets; nothing sensitive is committed by default.
