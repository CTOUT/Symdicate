# Security Policy

## Supported Versions

Symdicate is pre-1.0 software. Security fixes are applied to the `main` branch and released as new versions. There are no separate maintenance branches at this time.

| Version | Supported |
|---------|-----------|
| `main` (latest) | ✅ |
| Older tagged releases | ❌ |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

To report a vulnerability, email: **security@ctout.dev** (or open a [GitHub Security Advisory](https://github.com/CTOUT/Symdicate/security/advisories/new) directly).

Include in your report:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- Any suggested mitigations if you have them

You can expect:
- An acknowledgement within **48 hours**
- A status update within **7 days**
- Credit in the release notes if you'd like it (just let us know)

We ask that you give us reasonable time to address the issue before any public disclosure.

## Scope

This repository contains:
- A GitHub Copilot agent definition (`NeuroGraft.agent.md`)
- Persona files (`.persona.md`, `.guest.md`)
- Installer scripts (`install.ps1`, `install.sh`)
- A GitHub Actions workflow (`release.yml`)

Vulnerabilities in any of these are in scope. Areas of particular interest:
- The installer scripts fetching and executing remote content
- The GitHub Actions workflow and its permissions
- Prompt injection risks in agent instructions or persona files

## Installer Script Security Note

The one-liner install commands (`irm ... | iex`, `curl ... | bash`) execute code directly from this repository. To verify before running:

1. Download the script first and inspect it
2. Check the SHA-256 of the downloaded file against the checksums published on the [releases page](https://github.com/CTOUT/Symdicate/releases/latest)
3. Pin to a specific release tag rather than `main` for reproducible installs:
   ```powershell
   # PowerShell
   .\install.ps1 -Ref v1.0.0
   ```
   ```bash
   # Bash
   bash install.sh --ref v1.0.0
   ```
