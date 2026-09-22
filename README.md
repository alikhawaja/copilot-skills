# Copilot skills

Reusable skills for GitHub Copilot.

## Available skills

### `dev-machine-setup`

Sets up or repairs a Windows developer machine with:

- VS Code and development extensions
- Git, GitHub CLI, Git LFS, Windows OpenSSH, and SSH signing
- Python 3.14 and 3.13, uv, Ruff, Pyright, and pre-commit-compatible tooling
- PowerShell 7, Azure CLI, and Azure PowerShell
- Windows Terminal, Hyper-V, WSL 2, Ubuntu LTS, and Docker Desktop

The workflow preserves existing credentials, respects enterprise security
policy, explains elevation prompts, and verifies each installation.

## Install

Run the installer from a cloned copy of this repository:

```powershell
.\install.ps1 -Skill dev-machine-setup
```

Or copy the directory manually:

```powershell
Copy-Item -Recurse -Force `
  .\skills\dev-machine-setup `
  "$HOME\.copilot\skills\dev-machine-setup"
```

Restart GitHub Copilot after installing or updating a skill.

## Update

Pull the desired tagged release and rerun the installer:

```powershell
git pull --ff-only
.\install.ps1 -Skill dev-machine-setup
```

## Security

Review `SKILL.md` and any referenced scripts before installation. Skills can
instruct an agent to execute commands with the same permissions as the user.
This repository contains no credentials or machine-specific secrets.

## License

Licensed under the [MIT License](LICENSE).
