# Contributing to Frostflake

Thanks for your interest in improving Frostflake! This document explains how to propose changes, report bugs, and keep the repo healthy.

## Prerequisites
- Install [Nix](https://nixos.org/download.html) with flakes enabled.
- Run `direnv allow` once so the dev shell loads automatically.
- Install git hooks: `make hooks` (installs pre-commit, commit-msg, and pre-push hooks).

## Development workflow
1. Create a feature branch from `dev`.
2. Run `nix develop` (optional when direnv is active).
3. Make your changes.
4. Run formatting + tests:
   ```sh
   nix fmt
   nix flake check
   make lint   # wraps pre-commit run --all-files
   ```
5. Open an issue/PR with a clear description, linking related issues.

## Commit standards
- Keep commits focused; describe both the problem and the solution.
- Do not commit plaintext secrets. Use `make secret-host HOST=<name>` or `make secret-edit FILE=shared.yaml` to edit encrypted files via sops.
- Ensure `nix fmt`, `statix`, `deadnix`, and `nix flake check` pass before pushing.

## Pull requests
- Fill out the PR template (`.github/pull_request_template.md`).
- Include screenshots/logs if the change affects user-visible behavior.
- Update documentation (`README.md`, `docs/*`) when altering workflows or modules.

## Code owners & reviews
- `CODEOWNERS` routes module/host changes to @j4v3l.
- All PRs require review + green CI before merging.

## Reporting bugs or requesting features
- Use the issue templates under `.github/ISSUE_TEMPLATE` (Bug Report or Feature Request).
- Provide steps to reproduce, host context, and relevant logs.

## Security disclosures
- Please see `SECURITY.md` for responsible disclosure instructions.

Thanks again for helping make Frostflake better!
