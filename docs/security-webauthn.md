# WebAuthn / YubiKey Enforcement

This repository now ships with a dedicated `frostflake.security.webauthn` module that enables FIDO2-bound authentication across every Linux host. The module is imported automatically in `lib/frostflake/mk-linux-host.nix`, so all current and future machines inherit the policy unless they explicitly opt out.

## Module overview

```nix
frostflake.security.webauthn = {
  enable = true;                      # Set to false within a host to disable entirely.
  pamServices = ["login" "sudo" "sshd" "polkit-1"];
  mappingFile = "/etc/security/u2f-mappings";
  mappingFileSource = null;           # Point to a secret file to manage the mapping declaratively.
  allowUserOptOut = true;             # Users in frostflake-webauthn-exempt skip pam_u2f.
  exemptGroup = "frostflake-webauthn-exempt";
  ssh = {
    hardwareOnly = true;              # Restrict sshd to *-sk hardware key algorithms.
    allowedAlgorithms = [
      "sk-ssh-ed25519@openssh.com"
      "sk-ecdsa-sha2-nistp256@openssh.com"
    ];
    authenticationMethods = "publickey";
  };
};
```

Key behaviors:


Disable the policy per host by adding the following snippet anywhere inside that host’s `extraConfig`:

```nix
  frostflake.security.webauthn.enable = false;
```

## Per-user controls

The default `frostflakeUser` definition now includes a `security` block:

```nix
security = {
  requireWebauthn = true;             # Set to false to automatically join the exempt group.
  ssh = {
    hardwareKeys = [];
    softFallbackKeys = [];
    allowSoftFallback = false;        # If true, softFallbackKeys append to authorized_keys.
  };
};
```


## Enrollment workflow

1. **Enroll WebAuthn with pam_u2f** on each machine where the user logs in:
   ```bash
   mkdir -p ~/.config/Yubico
   pamu2fcfg -u "$(whoami)" > ~/.config/Yubico/u2f_keys
   ```
2. **Store the mapping file** via SOPS (see `docs/secrets.md`). The
  `frostflake.secrets` module now looks for a `pam_u2f_mappings` key inside
  `secrets/shared.yaml` and renders it to `/etc/security/u2f-mappings` during
  activation, so no plaintext blobs ever ship in the repo.
3. **Generate hardware-backed SSH keys (resident)** so the key is portable and the stub can be recreated on any client with the YubiKey present:
   ```bash
  ssh-keygen -t ed25519-sk -O resident -O verify-required -C "frostflake hardware key" -f ~/.ssh/id_ed25519_sk
   ```
  Add the resulting public key (`~/.ssh/id_ed25519_sk.pub`) to `frostflakeUser.security.ssh.hardwareKeys` (or the corresponding user definition).
  To restore the stub on a new client, plug in the YubiKey and run `ssh-keygen -K -f ~/.ssh/id_ed25519_sk`.
5. **Test locally** before rollout:
   ```bash
  rg -n pam_u2f /etc/pam.d       # Confirm pam_u2f is present
  ssh -o PubkeyAcceptedAlgorithms=+sk-ssh-ed25519@openssh.com localhost
   ```

## Handy commands

- `yubi-pam-enroll`: opens a pam_u2f enrollment prompt and writes the mapping line to `/tmp/u2f_mapping_$USER` for copy/paste into `secrets/shared.yaml`.
- `yubi-ssh-key`: creates a resident `~/.ssh/id_ed25519_sk` if it does not already exist (portable across clients with the YubiKey present).
- `yk-info`: quick YubiKey status via `ykman info`.
- `yk-oath-list`: list stored OATH accounts via `ykman oath accounts list`.

These are available as `zsh` aliases (via home-manager) and just call the `Makefile` or `ykman` directly; ensure the `frostflake.security.webauthn` module remains enabled so the required packages (libfido2, yubikey-manager, yubikey-personalization, yubico-pam) stay installed.

## Operational tips
