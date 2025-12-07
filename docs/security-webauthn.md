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
      "ssh-ed25519-sk"
      "ecdsa-sha2-nistp256-sk"
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
3. **Generate hardware-backed SSH keys** using each YubiKey:
   ```bash
   ssh-keygen -t ed25519-sk -C "frostflake hardware key"
   ```
   Add the resulting public key (`~/.ssh/id_ed25519_sk.pub`) to `frostflakeUser.security.ssh.hardwareKeys` (or the corresponding user definition).
4. **Optional resident credentials**: append `-O resident` to `ssh-keygen` if you want discoverable keys.
5. **Test locally** before rollout:
   ```bash
   sudo pam-auth-update --list   # Confirm pam_u2f is present
  ssh -o PubkeyAcceptedAlgorithms=+ssh-ed25519-sk localhost
   ```

## Operational tips

