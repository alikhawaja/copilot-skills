---
name: dev-machine-setup
description: >-
  Set up or repair a Windows, macOS, or Linux developer machine with VS Code,
  Git and GitHub SSH, Python 3.14 and 3.13, uv, Ruff, Pyright,
  pre-commit-compatible tooling, PowerShell 7, Azure CLI and Azure PowerShell,
  and Docker. On Windows, also configures Windows Terminal, Hyper-V, WSL 2, and
  the latest Ubuntu LTS. Use when the user asks to provision, bootstrap,
  configure, verify, or repair a development machine.
---

# Cross-platform developer machine setup

Provision the machine incrementally, preserve existing configuration, and verify
every installed surface. Produce the same development capabilities on Windows,
macOS, and Linux while using each platform's native conventions.

## Safety and interaction rules

- Detect the operating system, architecture, package manager, shell, and
  privilege model before planning installations. Never run commands for another
  platform.
- Ask for the Git user name, Git email, and preferred source root if not given.
  Default to `$HOME\git` on Windows and `$HOME/git` on macOS/Linux.
- Inventory existing versions and configuration before changing them. Upgrade
  in place when possible; do not install duplicate package-manager variants.
- Explain every elevation prompt immediately before invoking it. Batch package
  operations when the package manager supports it.
- Never overwrite an existing SSH private key or request a passphrase in chat.
  Use an interactive terminal for `ssh-keygen`, `ssh-add`, GitHub device login,
  and operating-system credential prompts.
- Do not disable TLS validation, execution policy, Gatekeeper, SELinux,
  antivirus, application control, or administrator policy.
- Do not pipe a remote script directly into a shell. Download it over HTTPS,
  inspect its origin/content, then execute the local file.
- Respect managed-device network policy. If `files.pythonhosted.org` or another
  package host is blocked, use approved system packages or ask for the
  organization's approved mirror. Never evade a block.
- Preserve unrelated Git, SSH, shell, Docker, and editor configuration. Add or
  update only the entries needed for this setup.
- Treat installer success as provisional until the actual executable and
  expected version are verified from a fresh shell.

## 1. Detect the platform

### Windows

```powershell
$platform = 'windows'
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
Get-CimInstance Win32_OperatingSystem |
  Select-Object Caption, Version, BuildNumber, OSArchitecture
winget --version
```

Prefer Winget. Determine whether the host is Home, Pro, Enterprise, or Education
before enabling Hyper-V.

### macOS

```bash
platform=macos
sw_vers
uname -m
xcode-select -p 2>/dev/null || true
command -v brew || true
```

Install Apple Command Line Tools interactively if absent:

```bash
xcode-select --install
```

Prefer Homebrew. If Homebrew is missing, ask for approval before installing it
from the official Homebrew source. On Apple Silicon, ensure `/opt/homebrew/bin`
is initialized through `brew shellenv`; on Intel, use `/usr/local/bin`.

### Linux

```bash
platform=linux
uname -a
cat /etc/os-release
uname -m
command -v apt-get || command -v dnf || command -v pacman || command -v zypper
```

Support these families as first-class paths:

| Family | Detection | Package manager |
|---|---|---|
| Debian/Ubuntu | `ID=debian` or `ID=ubuntu` | `apt-get` |
| Fedora/RHEL-compatible | `ID=fedora`, `rhel`, `rocky`, `almalinux` | `dnf` |
| Arch-compatible | `ID=arch`, `manjaro` | `pacman` |
| openSUSE | `ID=opensuse-*`, `sles` | `zypper` |

For an unsupported distribution, do not guess repository URLs. Use a supported
universal installer or consult the vendor's official instructions for the exact
distribution and version.

## 2. Inventory

Check available tools without failing the whole inventory when one is absent:

```text
VS Code:          code --version
Python:           python3 --version; python --version
Python manager:   uv --version
Python tools:     ruff --version; pyright --version; prek --version
Git:              git --version; git lfs version
GitHub CLI:       gh --version; gh auth status
SSH:              ssh -V; ssh-add -l
PowerShell:       pwsh --version
Azure:            az version
Azure PowerShell: pwsh -NoProfile -Command "Get-Module Az -ListAvailable"
Docker:           docker version
```

On Windows, also check:

```powershell
py --list-paths
wt --version
wsl --status
wsl --list --verbose
```

Confirm or create the source root only after the user agrees. Inspect global Git
configuration and the SSH directory before changing either.

## 3. Install the editor

### Windows

```powershell
winget install --exact --id Microsoft.VisualStudioCode --scope user `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

### macOS

```bash
brew install --cask visual-studio-code
```

### Linux

Use Microsoft's official repository/package for the detected distribution.

For Debian/Ubuntu, configure Microsoft's signed APT repository rather than
downloading an untracked `.deb`. For Fedora/RHEL-compatible systems, configure
the signed Microsoft RPM repository. On Arch-compatible systems, ask whether
the user accepts the community-maintained `visual-studio-code-bin` AUR package;
otherwise use Microsoft's official archive under `/opt` with a managed symlink.

Never silently substitute Code OSS when the user requested Microsoft VS Code,
because extension availability and telemetry behavior differ.

### Shared extensions

After `code` resolves in a fresh shell:

```bash
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension charliermarsh.ruff
code --install-extension GitHub.vscode-pull-request-github
code --install-extension ms-vscode.vscode-node-azure-pack
```

Install extensions one at a time and verify with
`code --list-extensions --show-versions`. Do not force-install
`GitHub.copilot` when Copilot Chat is built into the current VS Code release;
forcing it can attempt to downgrade a built-in extension.

## 4. Install uv, Python, and Python tools

Use uv to provide consistent Python versions on all platforms:

```bash
uv python install 3.14 3.13
uv python list
```

This avoids relying on the operating system's Python release cadence. Never
replace or unlink the system Python used by macOS or Linux package management.
Use `uv run`, project virtual environments, or explicit `uv python` executables.

### Install uv on Windows

```powershell
winget install --exact --id astral-sh.uv `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

If the user explicitly wants Python registered with the Windows `py` launcher,
also install the official side-by-side packages:

```powershell
$pyArgs = 'InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0 Include_doc=0 Include_tcltk=1 Include_pip=1 Shortcuts=0 SimpleInstall=1'
winget install --exact --id Python.Python.3.14 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent --override $pyArgs
winget install --exact --id Python.Python.3.13 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent --override $pyArgs
```

Do not pass `--scope user` to these Python Winget packages; that can filter out
their otherwise valid installers.

### Install uv on macOS

```bash
brew install uv
```

### Install uv on Linux

Use a distribution package if it provides a current uv release. Otherwise,
download the official installer for review:

```bash
tmp="$(mktemp)"
curl --proto '=https' --tlsv1.2 -LsSf \
  https://astral.sh/uv/install.sh -o "$tmp"
sed -n '1,200p' "$tmp"
sh "$tmp"
rm -f "$tmp"
```

Reload the shell environment before verifying `uv`.

### Shared Python developer tools

```bash
uv tool install ruff
uv tool install pyright
uv tool install pre-commit
uv tool list
```

If PyPI is blocked, use policy-approved alternatives:

- **Windows:** Winget `astral-sh.ruff`, Node.js LTS plus npm `pyright`, and
  Winget `j178.Prek`.
- **macOS:** `brew install ruff pyright prek`.
- **Linux:** use current distribution packages where available; otherwise ask
  for the approved Python/npm mirror. Do not silently use a public proxy.

`prek` is a compatible pre-commit runner. On Windows, do not weaken execution
policy for npm's `.ps1` shim; use `pyright.cmd` when needed.

## 5. Install and configure Git tooling

### Windows

```powershell
winget install --exact --id Git.Git `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
winget install --exact --id GitHub.cli `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
winget install --exact --id GitHub.GitLFS `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

### macOS

```bash
brew install git gh git-lfs
```

### Linux

Install `git`, `git-lfs`, and the GitHub CLI package using the detected package
manager. Prefer GitHub's signed official repository for `gh` if the
distribution's repository does not provide it.

Common package names:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y git git-lfs gh

# Fedora/RHEL-compatible
sudo dnf install -y git git-lfs gh

# Arch-compatible
sudo pacman -S --needed git git-lfs github-cli

# openSUSE
sudo zypper install git git-lfs gh
```

If a package is unavailable, configure the vendor's official signed repository
for the exact distribution rather than falling back to an arbitrary binary.

### Shared Git configuration

```bash
git lfs install --skip-repo
git config --global user.name '<git-user-name>'
git config --global user.email '<git-email>'
git config --global init.defaultBranch main
git config --global core.editor 'code --wait'
git config --global credential.helper manager
```

Only set `credential.helper manager` if Git Credential Manager is installed.
On macOS, `osxkeychain` is a valid native fallback. On Linux, do not configure
plaintext credential storage.

Copilot Desktop can inject private Git/gh binaries into its own process `PATH`.
When versions appear stale, compare `command -v -a git gh` or
`Get-Command git,gh -All` with the persistent shell `PATH`.

## 6. Configure SSH and GitHub

Use `~/.ssh/id_ed25519_github` unless the user chooses another path. Preserve an
existing key:

```bash
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
test -f "$HOME/.ssh/id_ed25519_github" ||
  ssh-keygen -t ed25519 -C '<git-email>' \
    -f "$HOME/.ssh/id_ed25519_github"
```

Run `ssh-keygen` interactively so the user can enter a passphrase securely.

Append a `Host github.com` block only if one does not already exist:

```text
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
    AddKeysToAgent yes
```

On macOS, add `UseKeychain yes` to that block and load the key with:

```bash
ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519_github"
```

On Linux, reuse the desktop/session SSH agent when `$SSH_AUTH_SOCK` is set. If
no agent exists, start one for the current session:

```bash
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_ed25519_github"
```

Do not add `eval "$(ssh-agent -s)"` to every shell startup automatically; that
creates orphaned agents. Offer a desktop keyring, `keychain`, or a user systemd
service if the user wants persistence.

On Windows, enable and use Windows OpenSSH from elevated PowerShell:

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service -Name ssh-agent
ssh-add "$env:USERPROFILE\.ssh\id_ed25519_github"
git config --global core.sshCommand 'C:/Windows/System32/OpenSSH/ssh.exe'
git config --global gpg.ssh.program `
  'C:/Windows/System32/OpenSSH/ssh-keygen.exe'
```

Configure SSH commit and tag signing on every platform:

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_github.pub
git config --global commit.gpgsign true
git config --global tag.gpgSign true
```

Authenticate GitHub and upload the key:

```bash
gh auth login --hostname github.com --git-protocol ssh
```

Register the public key separately as a signing key so GitHub can verify
commits:

```bash
gh auth refresh --hostname github.com --scopes admin:ssh_signing_key
gh ssh-key add "$HOME/.ssh/id_ed25519_github.pub" \
  --type signing --title '<machine name> signing key'
```

Verify:

```bash
ssh-add -l
ssh -o StrictHostKeyChecking=accept-new -T git@github.com
```

GitHub's successful SSH greeting exits with status 1 because it does not provide
shell access. Treat `You've successfully authenticated` as success.

## 7. Install PowerShell and Azure tools

### Windows

```powershell
winget install --exact --id Microsoft.PowerShell `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
winget install --exact --id Microsoft.AzureCLI `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

PowerShell may be an MSIX package under WindowsApps. Resolve it through `pwsh`
or `$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe`; do not assume the legacy
`C:\Program Files\PowerShell\7` path.

### macOS

```bash
brew install --cask powershell
brew install azure-cli
```

### Linux

Install both tools from Microsoft's signed repository for the exact detected
distribution and release. On Debian/Ubuntu, use the matching
`packages-microsoft-prod` configuration package. On Fedora/RHEL-compatible
systems, use Microsoft's matching signed RPM repository. Do not reuse an Ubuntu
or RHEL repository on a different distribution.

After configuring the repository, package names are normally:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y powershell azure-cli

# Fedora/RHEL-compatible
sudo dnf install -y powershell azure-cli
```

For Arch/openSUSE or unsupported versions, prefer official release packages or
containers and verify checksums. Do not invent a repository URL.

### Shared Azure PowerShell module

Install from PowerShell 7:

```powershell
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Install-PSResource -Name Az -Repository PSGallery -Scope CurrentUser `
  -TrustRepository -Quiet -AcceptLicense
Get-Module Az -ListAvailable |
  Sort-Object Version -Descending |
  Select-Object -First 1 Name, Version
```

If PSGallery is blocked, ask for the approved PowerShell repository. Do not
permanently trust a substitute feed without confirmation.

## 8. Install Docker

### Windows

Install Docker Desktop:

```powershell
winget install --exact --id Docker.DockerDesktop `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Complete the WSL 2 setup in the Windows-only section before starting Docker.

### macOS

Install Docker Desktop:

```bash
brew install --cask docker
```

Launch Docker once through Finder or `open -a Docker`, let the user accept the
license and privileged helper prompt, then wait until `docker info` succeeds.
On managed Macs, respect the organization's approved container runtime.

### Linux

Prefer Docker Engine from Docker's official signed repository for the exact
distribution. Remove only conflicting packages explicitly identified by
Docker's documentation; never remove container runtimes speculatively.

Enable the service after installation:

```bash
sudo systemctl enable --now docker
sudo systemctl enable --now containerd
```

Adding the user to the `docker` group grants root-equivalent access. Explain
that risk and ask before running:

```bash
sudo usermod -aG docker "$USER"
```

The user must log out and back in for group membership to apply. Rootless
Docker is the preferred alternative when supported by the workload.

## 9. Windows-only virtualization, WSL 2, and Ubuntu

Skip this section entirely on macOS and Linux.

Install Windows Terminal:

```powershell
winget install --exact --id Microsoft.WindowsTerminal `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Check Windows edition and virtualization:

```powershell
Get-CimInstance Win32_OperatingSystem |
  Select-Object Caption, Version, BuildNumber
systeminfo.exe | Select-String 'Hyper-V Requirements'
```

Full Hyper-V is supported on Pro, Enterprise, and Education, not Home. Do not
apply unofficial Home workarounds. WSL 2 uses Virtual Machine Platform and is
supported independently of the full Hyper-V management feature.

From elevated PowerShell, enable supported features idempotently:

```powershell
$features = @(
  'VirtualMachinePlatform',
  'Microsoft-Windows-Subsystem-Linux',
  'HypervisorPlatform'
)
if ((Get-CimInstance Win32_OperatingSystem).Caption -notmatch ' Home') {
  $features += 'Microsoft-Hyper-V-All'
}
foreach ($feature in $features) {
  $state = Get-WindowsOptionalFeature -Online -FeatureName $feature
  if ($state.State -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName $feature `
      -All -NoRestart | Out-Null
  }
}
bcdedit /set hypervisorlaunchtype auto
```

Keep service startup types aligned with Windows defaults while ensuring they
are not disabled:

```powershell
$serviceModes = @{
  vmms        = 'Automatic'
  vmcompute   = 'Manual'
  hns         = 'Manual'
  HvHost      = 'Manual'
  WslService  = 'Automatic'
  LxssManager = 'Automatic'
}
foreach ($name in $serviceModes.Keys) {
  if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
    Set-Service -Name $name -StartupType $serviceModes[$name]
  }
}
```

Enable WSL without silently selecting an old default distribution:

```powershell
wsl --install --no-distribution
wsl --set-default-version 2
wsl --list --online
```

Select the highest Ubuntu version that the live catalog explicitly labels LTS;
never hardcode a previously current release. Install without launching:

```powershell
wsl --install -d <latest-Ubuntu-LTS-name> --no-launch
```

After feature changes, stop and tell the user a reboot is mandatory. Do not
interpret pre-reboot WSL/Docker virtualization errors as permanent failures.

After reboot:

1. Launch the installed Ubuntu distribution and let the user create its Linux
   username and password interactively.
2. Set it as the default and confirm version 2:

```powershell
wsl --set-default <latest-Ubuntu-LTS-name>
wsl --set-version <latest-Ubuntu-LTS-name> 2
wsl --list --verbose
```

3. Start Docker Desktop, let the user accept its terms, select the WSL 2
   backend, and enable integration with the Ubuntu distribution.

## 10. Final verification

Run checks from a newly opened login shell so package-manager `PATH` changes are
present.

### Shared checks

```text
code --version
uv --version
uv python list
python3 --version or the selected uv-managed Python
ruff --version
pyright --version
pre-commit --version or prek --version
git --version
git lfs version
gh --version
gh auth status
ssh-add -l
pwsh --version
az version
pwsh -NoProfile -Command "Get-Module Az -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version"
docker version
docker info
docker run --rm hello-world
```

### Windows additions

```powershell
py --list-paths
wt --version
wsl --list --verbose
wsl -d <latest-Ubuntu-LTS-name> -- uname -a
wsl -d <latest-Ubuntu-LTS-name> -- cat /etc/os-release
```

### macOS additions

```bash
brew doctor
brew list --versions git gh git-lfs uv azure-cli
system_profiler SPSoftwareDataType
```

### Linux additions

```bash
cat /etc/os-release
systemctl is-enabled docker
systemctl is-active docker
id
```

Report exact installed versions, package sources, policy restrictions, reboot
or re-login requirements, and interactive first-run steps. Distinguish
installed, configured, authenticated, and operational states. A task is not
complete until the requested tools are operational on the detected platform.
