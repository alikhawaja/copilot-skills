---
name: dev-machine-setup
description: >-
  Set up or repair a Windows, macOS, or Linux developer machine with VS Code,
  Git, GitHub SSH, GitHub Copilot CLI, Python 3.14 and 3.13, uv, Ruff, Pyright,
  pre-commit-compatible tooling, the latest stable .NET SDK, C# Dev Kit,
  native C/C++ compilers, PowerShell 7, Azure CLI, Azure PowerShell, and Docker.
  On Windows, also configures Explorer integration, Visual Studio Build Tools,
  Power BI Desktop, Windows Terminal, Hyper-V, WSL 2, and the latest Ubuntu LTS.
  Use when the user asks to provision, bootstrap, configure, verify, or repair a
  development machine.
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
.NET SDK:         dotnet --info; dotnet --list-sdks
C# extensions:    code --list-extensions --show-versions
Native compiler:  cl, clang, or cc --version
Git:              git --version; git lfs version
GitHub CLI:       gh --version; gh auth status
Copilot CLI:      copilot --version
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
winget list --exact --id Microsoft.PowerBI --source winget `
  --accept-source-agreements
wsl --status
wsl --list --verbose
```

Also inspect Visual Studio and MSVC components when present:

```powershell
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
  & $vswhere -products '*' -format json
}
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

### Windows Explorer integration

On Windows 11, prefer the official Microsoft VS Code installer integration.
The installer tasks `addcontextmenufiles` and `addcontextmenufolders` register
the signed sparse AppX package `Microsoft.VisualStudioCode`. Its manifest uses
`windows.fileExplorerContextMenus` for `Directory`,
`Directory\Background`, and `*`, with verb `OpenWithCode` and CLSID
`1C6DF0C0-192A-4451-BE36-6A59A86A692E`. This IExplorerCommand-style
registration is what can place **Open with Code** directly in the Windows 11
compact context menu. Plain `...\shell\...` registry verbs are legacy commands
and normally appear only under **Show more options** or `Shift+F10`.

Inventory the installed VS Code record and its selected Inno Setup tasks without
changing anything:

```powershell
$uninstallRoots = @(
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$vscodeInstaller = Get-ChildItem $uninstallRoots -ErrorAction SilentlyContinue |
  Get-ItemProperty |
  Where-Object DisplayName -Like 'Microsoft Visual Studio Code*' |
  Select-Object DisplayName, DisplayVersion, InstallLocation,
    'Inno Setup: Selected Tasks', UninstallString
$vscodeInstaller
```

Inspect the sparse package and the relevant manifest declarations:

```powershell
$package = Get-AppxPackage -Name Microsoft.VisualStudioCode
$package | Select-Object Name, PackageFullName, InstallLocation, SignatureKind,
  Status

if ($package) {
  $manifestPath = Join-Path $package.InstallLocation 'AppxManifest.xml'
  [xml]$manifest = Get-Content -LiteralPath $manifestPath -Raw
  $manifest.SelectNodes(
    "//*[local-name()='Extension' and @Category='windows.fileExplorerContextMenus']"
  ) | ForEach-Object {
    [pscustomobject]@{
      Category = $_.Category
      XML = $_.OuterXml
    }
  }
}
```

The x64 and x86 Visual C++ redistributables may both be healthy while this menu
integration is absent. Treat them as independent prerequisites, not evidence
that either VS Code context-menu task is registered.

An existing sparse package does not prove the optional installer tasks were
selected. If either context-menu task is absent, repair the current user install
with the latest Microsoft-signed **user installer** from the official VS Code
update service. Do not downgrade merely because Winget's catalog trails VS
Code's internal updater. Compare the installed version first, and use Winget
only when it offers the same or a newer stable version.

VS Code must be fully closed before rerunning its installer. Ask the user to
close every VS Code window, then verify with:

```powershell
Get-Process Code -ErrorAction SilentlyContinue
```

Do not force-close VS Code or terminate its processes unless the user explicitly
approves; unsaved editor state may be lost.

Download the installer to a temporary file, verify Authenticode before running
it, and merge the two tasks so all existing selections such as
`associatewithfiles`, `addtopath`, and `runcode` remain enabled:

```powershell
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$platform = switch ($architecture) {
  'X64'   { 'win32-x64-user' }
  'Arm64' { 'win32-arm64-user' }
  default { throw "Unsupported VS Code user-installer architecture: $architecture" }
}
$installer = Join-Path $env:TEMP "VSCodeUserSetup-$architecture.exe"
$uri = "https://update.code.visualstudio.com/latest/$platform/stable"
Invoke-WebRequest -Uri $uri -OutFile $installer

$signature = Get-AuthenticodeSignature -LiteralPath $installer
if ($signature.Status -ne 'Valid' -or
    $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
  throw "VS Code installer signature is not valid and Microsoft-signed: $($signature.Status)"
}
$signature | Select-Object Status,
  @{Name='Signer'; Expression={$_.SignerCertificate.Subject}}

if (Get-Process Code -ErrorAction SilentlyContinue) {
  throw 'Close VS Code fully before rerunning the installer. Processes were not terminated.'
}

Start-Process -FilePath $installer -Wait -ArgumentList @(
  '/MERGETASKS="addcontextmenufiles,addcontextmenufolders"'
)
Remove-Item -LiteralPath $installer
```

After installation, repeat the selected-task and AppX manifest inventory. The
selected task list should include both context tasks while retaining every
previous task. Reopen File Explorer if needed and verify **Open with Code**
appears directly in the compact menu for a file, a folder, and folder
background.

#### Legacy classic-menu-only fallback

Use this only when the official signed installer registration cannot be
repaired. It does not provide Windows 11 compact-menu integration. Use the
non-installer-owned key name `OpenWithVSCode` so the fallback is distinguishable
from official registration:

```powershell
$code = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
if (-not (Test-Path -LiteralPath $code)) {
  throw "VS Code executable not found: $code"
}

$entries = @(
  @{ Key = 'HKCU\Software\Classes\*\shell\OpenWithVSCode'; Target = '%1' },
  @{ Key = 'HKCU\Software\Classes\Directory\shell\OpenWithVSCode'; Target = '%1' },
  @{ Key = 'HKCU\Software\Classes\Directory\Background\shell\OpenWithVSCode'; Target = '%V' }
)
foreach ($entry in $entries) {
  $command = '"{0}" "{1}"' -f $code, $entry.Target
  reg.exe add $entry.Key /ve /d 'Open with Code' /f | Out-Null
  reg.exe add $entry.Key /v Icon /t REG_SZ /d $code /f | Out-Null
  reg.exe add "$($entry.Key)\command" /ve /d $command /f | Out-Null
}
```

Once the official compact-menu integration works, remove these fallback keys to
avoid duplicate commands:

```powershell
@(
  'HKCU\Software\Classes\*\shell\OpenWithVSCode',
  'HKCU\Software\Classes\Directory\shell\OpenWithVSCode',
  'HKCU\Software\Classes\Directory\Background\shell\OpenWithVSCode'
) | ForEach-Object { reg.exe delete $_ /f 2>$null }
```

## 4. Install the .NET SDK, C# tooling, and native compilers

Install the highest stable .NET SDK available from the platform's trusted
package source. Do not select a preview or release candidate unless the user
explicitly requests prerelease tooling. Runtimes alone are insufficient for
building projects; verify that `dotnet --list-sdks` returns at least one SDK.

### Windows

Discover the live stable SDK major before choosing the package:

```powershell
winget search --id Microsoft.DotNet.SDK --source winget `
  --accept-source-agreements
```

Install the highest non-preview major shown by that command:

```powershell
winget install --exact --id Microsoft.DotNet.SDK.<major> --source winget `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Install C# Dev Kit in VS Code. It installs the compatible C# extension as a
dependency:

```powershell
code --install-extension ms-dotnettools.csdevkit
code --list-extensions --show-versions |
  Select-String '^ms-dotnettools\.(csdevkit|csharp)@'
```

For MSVC, install Visual Studio Build Tools with the Desktop development with
C++ workload. Explain that this is a multi-gigabyte machine-wide installation
and that Windows may display a UAC prompt:

```powershell
winget install --exact --id Microsoft.VisualStudio.2022.BuildTools `
  --source winget --accept-package-agreements --accept-source-agreements `
  --disable-interactivity `
  --override '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'
```

`cl.exe` is intentionally available inside a Visual Studio developer
environment rather than on the global `PATH`. Verify the x64 compiler through
`vcvars64.bat`:

```powershell
$installerDir = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"
$vswhere = Join-Path $installerDir 'vswhere.exe'
$install = & $vswhere -latest -products '*' `
  -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
  -property installationPath
if (-not $install) {
  throw 'MSVC x64/x86 toolchain not found.'
}
$devcmd = Join-Path $install 'VC\Auxiliary\Build\vcvars64.bat'
& $env:ComSpec /c "set `"PATH=$installerDir;%PATH%`" && call `"$devcmd`" >nul && where cl && cl 2>&1"
```

### macOS

Use the current stable Homebrew .NET SDK cask and Apple's native compiler
toolchain:

```bash
brew install --cask dotnet-sdk
xcode-select -p >/dev/null 2>&1 || xcode-select --install
code --install-extension ms-dotnettools.csdevkit
dotnet --list-sdks
clang --version
```

Do not replace the Apple-provided Clang with an unrelated compiler unless the
project requires it. If `xcode-select --install` opens a dialog, let the user
complete it before verification.

### Linux

Install `dotnet-sdk-<major>.0` from Microsoft's signed repository configured for
the exact distribution and release. Do not mix Microsoft's repository with an
unrelated distribution package or install a preview accidentally. Install the
native build toolchain from the distribution:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y dotnet-sdk-<major>.0 build-essential cmake ninja-build pkg-config

# Fedora/RHEL-compatible
sudo dnf install -y dotnet-sdk-<major>.0 gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config

# Arch-compatible
sudo pacman -S --needed dotnet-sdk gcc cmake ninja pkgconf

# openSUSE
sudo zypper install dotnet-sdk-<major>.0 gcc gcc-c++ make cmake ninja pkg-config
```

Install C# Dev Kit after Microsoft VS Code is operational:

```bash
code --install-extension ms-dotnettools.csdevkit
code --list-extensions --show-versions |
  grep -E '^ms-dotnettools\.(csdevkit|csharp)@'
dotnet --list-sdks
cc --version
```

Respect C# Dev Kit's license terms and organization policy on every platform.

## 5. Install uv, Python, and Python tools

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

### Managed Python package feeds and Python 3.14 compatibility

When public package files are blocked, discover the approved pip configuration
without printing credentials:

```text
python -m pip config debug
python -m pip config list
```

Do not assume uv reads pip's global configuration. Pass the approved index
explicitly, or configure uv through the organization's approved mechanism:

```text
uv pip install --python <environment-python> \
  --index-url <approved-simple-index-url> \
  --requirements requirements.txt
```

For Python 3.14, perform a dry run when requirements are unpinned and verify
that compiled dependencies have compatible wheels. An old NumPy release may be
selected by transitive constraints and attempt a local source build. Do not
silently edit `requirements.txt`; use an explicit compatible constraint such as
`numpy>=2` only after checking the resolver plan, explain the change, and keep
the original requirements file intact unless the user asks for a reproducible
pin.

After installation, run both metadata and runtime checks:

```text
uv pip check --python <environment-python>
<environment-python> -c "import numpy, pandas, scipy, sklearn"
```

`uv pip check` cannot detect package API mismatches. Import representative
top-level packages, especially beta agent frameworks and their protocol
dependencies, and apply the narrowest version constraint only after confirming
the failing API boundary.

When the uv cache and environment are on different filesystems, use
`--link-mode copy` to avoid hardlink warnings; this is a performance/storage
choice, not a dependency fix.

## 6. Install and configure Git tooling

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

## 7. Configure SSH and GitHub

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

## 8. Install GitHub Copilot CLI

Install the stable standalone GitHub Copilot CLI only when the user has an
active Copilot subscription or organization-provided access. This is the
agentic `copilot` executable, not the retired GitHub CLI extension.

### Windows

Prefer the official Winget package:

```powershell
winget install --exact --id GitHub.Copilot `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

PowerShell 7 or later is required. Reload the persistent user and machine
`PATH`, or open a new terminal, before verification.

### macOS and Linux

Prefer the official Homebrew cask when Homebrew is available:

```bash
brew install --cask copilot-cli
```

If Homebrew is unavailable, download the official installer for inspection
rather than piping it directly into a shell:

```bash
tmp="$(mktemp)"
curl --proto '=https' --tlsv1.2 -fsSL \
  https://gh.io/copilot-install -o "$tmp"
sed -n '1,240p' "$tmp"
bash "$tmp"
rm -f "$tmp"
```

The installer defaults to `$HOME/.local` for a non-root user. Ensure its binary
directory is present in the login shell `PATH`.

### npm fallback on any platform

Use npm only when Node.js 22 or later is already part of the user's toolchain:

```bash
npm install --global @github/copilot
```

If npm has `ignore-scripts=true`, do not change the user's persistent npm
configuration. Apply the documented one-command override:

```bash
npm_config_ignore_scripts=false npm install --global @github/copilot
```

Do not install stable and prerelease packages side by side, and do not mix
Winget, Homebrew, and npm installations. Upgrade through the package manager
that owns the installed executable.

### Authentication and verification

Verify without starting an agent session:

```bash
copilot --version
copilot --help
```

Authentication is interactive:

```bash
copilot login
```

Let the user complete GitHub device authorization. Organization or enterprise
policy can disable Copilot CLI even when another Copilot surface works. Do not
create or request a personal access token unless device authentication is
unavailable and the user explicitly chooses that approach.

After login, confirm authentication with a harmless interactive launch or the
CLI's current account/status command if the installed version exposes one.
Never use a destructive prompt merely to test access.

## 9. Install PowerShell and Azure tools

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

## 10. Install Power BI Desktop on Windows

Skip this section entirely on macOS and Linux. Power BI Desktop is supported on
Windows only. On macOS or Linux, use the Power BI/Fabric web service or an
organization-approved Windows VM or remote desktop; do not use unsupported
compatibility-layer workarounds.

Inventory the official Winget package before installing or upgrading it:

```powershell
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
if ($architecture -ne 'X64') {
  Write-Warning "Detected $architecture. Confirm current Microsoft support for the x64 package and organization policy before installing."
}

winget list --exact --id Microsoft.PowerBI --source winget `
  --accept-source-agreements
winget show --exact --id Microsoft.PowerBI --source winget `
  --accept-source-agreements
```

Prefer Microsoft's official `Microsoft.PowerBI` Winget package and its x64
installer. Power BI Desktop is installed machine-wide, so Windows may display a
UAC prompt and require administrator approval even when Winget runs silently.
Explain the prompt immediately before installation and let the user approve it;
do not attempt to bypass elevation or enterprise application-control policy.

```powershell
winget install --exact --id Microsoft.PowerBI --source winget `
  --architecture x64 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Verify both Winget ownership and the live executable product version rather
than hardcoding a version from this document:

```powershell
winget list --exact --id Microsoft.PowerBI --source winget `
  --accept-source-agreements

$powerBIExe = @(
  "$env:ProgramFiles\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
  "${env:ProgramFiles(x86)}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $powerBIExe) {
  $powerBIExe = (Get-Command PBIDesktop.exe -ErrorAction SilentlyContinue).Source
}
if (-not $powerBIExe) {
  throw 'PBIDesktop.exe was not found after installation.'
}
Get-Item -LiteralPath $powerBIExe |
  Select-Object FullName,
    @{Name='ProductVersion'; Expression={$_.VersionInfo.ProductVersion}},
    @{Name='FileVersion'; Expression={$_.VersionInfo.FileVersion}}
```

First launch and sign-in are interactive. Power BI Desktop can create, open,
transform, and model local reports without publishing them. Publishing and
sharing require the appropriate Microsoft/Fabric/Power BI tenant access,
workspace permissions, and licensing. Respect enterprise tenant policies and
conditional-access requirements; never automate, store, or request user
credentials in chat.

## 11. Install Docker

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

## 12. Windows-only virtualization, WSL 2, and Ubuntu

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

## 13. Final verification

Run checks from a newly opened login shell so package-manager `PATH` changes are
present.

### Shared checks

```text
code --version
code --list-extensions --show-versions
dotnet --info
dotnet --list-sdks
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
copilot --version
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
winget list --exact --id Microsoft.PowerBI --source winget --accept-source-agreements
$powerBIExe = @(
  "$env:ProgramFiles\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
  "${env:ProgramFiles(x86)}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $powerBIExe) {
  $powerBIExe = (Get-Command PBIDesktop.exe -ErrorAction SilentlyContinue).Source
}
if (-not $powerBIExe) {
  throw 'PBIDesktop.exe was not found.'
}
(Get-Item -LiteralPath $powerBIExe).VersionInfo |
  Select-Object ProductVersion, FileVersion, FileName
$installerDir = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer"
$vswhere = Join-Path $installerDir 'vswhere.exe'
$install = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$devcmd = Join-Path $install 'VC\Auxiliary\Build\vcvars64.bat'
& $env:ComSpec /c "set `"PATH=$installerDir;%PATH%`" && call `"$devcmd`" >nul && where cl && cl 2>&1"
wsl --list --verbose
wsl -d <latest-Ubuntu-LTS-name> -- uname -a
wsl -d <latest-Ubuntu-LTS-name> -- cat /etc/os-release
```

### macOS additions

```bash
brew doctor
brew list --versions git gh git-lfs uv azure-cli
brew list --cask --versions dotnet-sdk
clang --version
system_profiler SPSoftwareDataType
```

### Linux additions

```bash
cat /etc/os-release
cc --version
systemctl is-enabled docker
systemctl is-active docker
id
```

Report exact installed versions, package sources, policy restrictions, reboot
or re-login requirements, and interactive first-run steps. Distinguish
installed, configured, authenticated, and operational states. A task is not
complete until the requested tools are operational on the detected platform.
