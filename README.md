# Copilot skills

Reusable skills for GitHub Copilot.

## Available skills

### `dev-machine-setup`

Sets up or repairs a Windows, macOS, or Linux developer machine with:

- VS Code and development extensions
- Git, GitHub CLI, Git LFS, OpenSSH, and SSH signing
- Python 3.14 and 3.13, uv, Ruff, Pyright, and pre-commit-compatible tooling
- PowerShell 7, Azure CLI, and Azure PowerShell
- Docker Desktop on Windows/macOS or Docker Engine on Linux
- Windows Terminal, Hyper-V, WSL 2, and Ubuntu LTS on Windows

The workflow preserves existing credentials, respects enterprise security
policy, explains elevation prompts, and verifies each installation.

## Install

Run either installer from a cloned copy of this repository.

PowerShell 7 on Windows, macOS, or Linux:

```powershell
.\install.ps1 -Skill dev-machine-setup
```

macOS or Linux:

```bash
./install.sh dev-machine-setup
```

Or copy the directory manually on any platform:

```powershell
Copy-Item -Recurse -Force `
  .\skills\dev-machine-setup `
  "$HOME\.copilot\skills\dev-machine-setup"
```

```bash
cp -R ./skills/dev-machine-setup "$HOME/.copilot/skills/"
```

Restart GitHub Copilot after installing or updating a skill.

## Update

Pull the desired tagged release and rerun the installer:

```powershell
git pull --ff-only
.\install.ps1 -Skill dev-machine-setup
```

Or:

```bash
git pull --ff-only
./install.sh dev-machine-setup
```

## Security

Review `SKILL.md` and any referenced scripts before installation. Skills can
instruct an agent to execute commands with the same permissions as the user.
This repository contains no credentials or machine-specific secrets.

## License

Licensed under the [MIT License](LICENSE).
