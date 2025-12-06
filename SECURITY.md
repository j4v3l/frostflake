# Security Policy

## Supported versions
Security fixes track the `dev` branch until tagged releases exist. Once releases are published, the latest release and `dev` will receive patches; older branches may be fixed case-by-case.

## Reporting a vulnerability
If you discover a security vulnerability:
1. **Do not** open a public issue.
2. Email `jj4v3l@gmail.com` with the subject line `SECURITY: <brief summary>`.
3. Include:
   - A detailed description of the issue and potential impact.
   - Steps to reproduce or proof-of-concept if available.
   - Suggested remediation ideas, if any.
4. Expect an initial response within 5 business days.

## Handling sensitive material
- Never commit plaintext credentials or Age keys.
- Use the SOPS workflow described in `docs/secrets.md` (`make secret-*` helpers) for all secrets.
- Rotate Age recipients when access changes.

## Coordinated disclosure
We aim to provide fixes before any public disclosure. If coordinated release is required, we will work with reporters to set an appropriate embargo date.

Thank you for responsibly disclosing vulnerabilities and helping keep Frostflake secure!
