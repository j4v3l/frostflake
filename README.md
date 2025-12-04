# Frostflake

Multi-host Nix flake for the Avalanche (desktop), Aurora (laptop), Iceberg (VM), and Glacier (macOS) systems. It targets NixOS 25.11 with GNOME on Linux plus nix-darwin + Home Manager on macOS.

## Layout

- `flake.nix` – exposes NixOS, nix-darwin, dev shells, and formatters.
- `hosts/` – per-host entry points. Linux machines share the same base + GNOME modules, Glacier imports the nix-darwin stack.
- `modules/` – reusable building blocks (`linux-base`, `gnome`, the GPU selector, and the user module).
- `home/` – Home Manager profiles (common + Linux/Darwin overlays) that supply zsh, starship, aliases, etc.
- `.envrc` / `.direnv/` – enables `direnv` (`use flake`) for automatic shells.
- `.pre-commit-config.yaml` – runs `alejandra`, `statix`, `deadnix`, and `nix flake check` before each commit.

## Host matrix

| Host      | Platform          | GPU profile | Notes |
|-----------|-------------------|-------------|-------|
| Avalanche | x86_64 desktop    | `nvidia`    | RTX 5070 Ti + CUDA acceleration for Ollama. |
| Aurora    | x86_64 laptop     | `intel`     | Laptop power tweaks (`tlp`, disabled `power-profiles-daemon`). |
| Iceberg   | x86_64 VM         | `vm`        | Guest additions (`qemuGuest`, `spice-vdagentd`). |
| Glacier   | aarch64-darwin    | —           | nix-darwin + Homebrew apps (Brave, Cursor, LM Studio, Ollama, VS Code). |

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

## Home environment highlights

- Zsh with completions, autosuggestions, syntax highlighting, direnv hooks, and starship prompt (Nerdfonts are provisioned on both Linux and macOS).
- Aliases for modern dir tooling (`eza`, `tree`), Git helpers, and NixOS workflows (`nixup`, `nixboot`, `nixdry`, `nclean`, etc.).
- Common CLI packages: alejandra, direnv, eza, fd, ripgrep, glances, tree, starship, neovim, statix, deadnix. Linux adds GUI apps (Brave, Cursor, LM Studio, Ollama, VS Code, GNOME Terminal); macOS installs the GUI set via Homebrew.

## Customization checklist

- **Root disks** – update `fileSystems."/"` in each host to reflect the real device/UUID.
- **Drivers** – change `hardware.gpu.profile` (and, if needed, `services.ollama.acceleration`) to adopt a new GPU.
- **Packages** – extend `modules/system/linux-base.nix` or the Home Manager profiles for shared tooling.
- **Secrets** – add host-specific modules or overlays for secrets; nothing sensitive is committed by default.
