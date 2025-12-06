# Frostflake secrets directory

This folder intentionally ships without encrypted blobs. Use `sops` to create
per-host files under `secrets/hosts/<hostname>.yaml` and optionally a shared
`secrets/shared.yaml`. The `.sops.yaml` file at the repo root controls which
Age recipients may decrypt the files.

See `docs/secrets.md` for the full workflow, including Age key generation,
recipient rotation, and how secrets are wired into the NixOS modules.
