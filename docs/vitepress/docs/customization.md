
---
title: Customization Checklist
description: Checklist for customizing Frostflake for your hardware, drivers, and secrets.
lastUpdated: true
---

# Customization Checklist

- **Root disks** – update `fileSystems."/"` in each host to reflect the real device/UUID.
- **Drivers** – change `hardware.gpu.profile` (and, if needed, `services.ollama.acceleration`) to adopt a new GPU.
- **Packages** – extend `modules/system/linux-base.nix` or the Home Manager profiles for shared tooling.
- **Secrets** – add host-specific modules or overlays for secrets; nothing sensitive is committed by default.
