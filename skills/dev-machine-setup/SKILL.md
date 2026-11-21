---
name: dev-machine-setup
description: >-
  Set up or repair a Windows, macOS, or Linux developer machine with VS Code,
  Git, GitHub SSH, GitHub Copilot CLI, Python 3.14 and 3.13, uv, Ruff, Pyright,
  pre-commit-compatible tooling, the latest stable .NET SDK, C# Dev Kit,
  native C/C++ compilers, PowerShell 7, Azure CLI, Azure PowerShell, Docker,
  and official Unsloth Desktop for local models on supported hardware.
  On Windows, also configures Explorer integration, Visual Studio Build Tools,
  Discord, Slack, Microsoft Teams, Power BI Desktop, Windows Terminal,
  Hyper-V, WSL 2, and the latest Ubuntu LTS.
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
Local AI:         Unsloth Desktop app version, package ownership, setup status,
                  local model/format, selected backend, context, API binding
                  unsloth --help only if a CLI is already present
```

On Windows, also check:

```powershell
py --list-paths
wt --version
winget list --exact --id Microsoft.PowerBI --source winget `
  --accept-source-agreements
winget list --exact --id UnslothAI.Unsloth --source winget `
  --accept-source-agreements
$collaborationWingetIds = @(
  'Discord.Discord',
  'SlackTechnologies.Slack',
  'Microsoft.Teams'
)
foreach ($id in $collaborationWingetIds) {
  winget list --exact --id $id --accept-source-agreements
}
$collaborationAppxNames = @('91750D7E.Slack', 'MSTeams')
$collaborationAppxNames | ForEach-Object { Get-AppxPackage -Name $_ } |
  Select-Object Name, Version, Architecture, PackageFullName, InstallLocation,
    SignatureKind, Status
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

## 10. Install collaboration applications

### Windows

Inventory both Winget registrations and AppX/MSIX/Microsoft Store packages
before changing anything. Winget can recognize some Store packages, but its
package ID alone does not prove that the installed application is the Win32 EXE
variant. Keep the AppX inventory as the authoritative ownership check for
Store/MSIX installations:

```powershell
$wingetIds = @(
  'Discord.Discord',
  'SlackTechnologies.Slack',
  'Microsoft.Teams'
)
foreach ($id in $wingetIds) {
  winget list --exact --id $id --accept-source-agreements
  winget show --exact --id $id --source winget --accept-source-agreements
}

$storePackages = @('91750D7E.Slack', 'MSTeams') |
  ForEach-Object { Get-AppxPackage -Name $_ }
$storePackages |
  Select-Object Name, Version, Architecture, PackageFullName, InstallLocation,
    SignatureKind, Status
```

Use these official stable Winget IDs for applications that are genuinely
missing:

| Application | Winget ID | Store/AppX name |
|---|---|---|
| Discord | `Discord.Discord` | None expected |
| Slack | `SlackTechnologies.Slack` | `91750D7E.Slack` |
| Microsoft Teams | `Microsoft.Teams` | `MSTeams` |

Discord may be disallowed by enterprise policy. Install it only when the user
requested it or the organization approved it. Do not use Teams Classic or
Teams Free unless the user explicitly requests that distinct product.

An application is already present when either its healthy Winget-owned package
or its healthy Store/AppX package is installed. In particular, do not install
`SlackTechnologies.Slack` when `91750D7E.Slack` is healthy; doing so creates
duplicate installations with separate update channels. Upgrade each application
through the package manager or self-update channel that owns the installed
copy. Slack and Teams catalog versions can lag versions delivered through their
self-update or Microsoft Store channels. Never downgrade a newer healthy
installation merely because `winget show` reports an older catalog version.

Install only the missing applications, explicitly selecting stable x64
packages:

```powershell
winget install --exact --id Discord.Discord --source winget `
  --architecture x64 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
winget install --exact --id SlackTechnologies.Slack --source winget `
  --architecture x64 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
winget install --exact --id Microsoft.Teams --source winget `
  --architecture x64 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Run only the command for an application confirmed missing after both
inventories. Do not auto-launch the applications, add them to startup, or
change existing startup settings.

Verify package ownership and versions again. For AppX/MSIX applications, also
resolve executable metadata from the signed package manifest. For Win32
installations, inspect a discovered executable rather than assuming one fixed
installation path:

```powershell
foreach ($id in $wingetIds) {
  winget list --exact --id $id --accept-source-agreements
}

$storePackages = @('91750D7E.Slack', 'MSTeams') |
  ForEach-Object { Get-AppxPackage -Name $_ }
$storePackages |
  Select-Object Name, Version, Architecture, PackageFullName, SignatureKind,
    Status

foreach ($package in $storePackages) {
  $manifest = Get-AppxPackageManifest -Package $package
  foreach ($application in $manifest.Package.Applications.Application) {
    $relativeExecutable = [string]$application.Executable
    if (-not $relativeExecutable) {
      continue
    }
    $executable = Join-Path $package.InstallLocation $relativeExecutable
    if (Test-Path -LiteralPath $executable) {
      Get-Item -LiteralPath $executable |
        Select-Object FullName,
          @{Name='ProductVersion'; Expression={$_.VersionInfo.ProductVersion}},
          @{Name='FileVersion'; Expression={$_.VersionInfo.FileVersion}}
    }
  }
}

$win32Executables = @(
  Get-ChildItem "$env:LOCALAPPDATA\Discord\app-*\Discord.exe" `
    -ErrorAction SilentlyContinue
  Get-Item "$env:LOCALAPPDATA\slack\slack.exe" -ErrorAction SilentlyContinue
  Get-Item "$env:ProgramFiles\Slack\slack.exe" -ErrorAction SilentlyContinue
) | Sort-Object FullName -Unique
$win32Executables |
  Select-Object FullName,
    @{Name='ProductVersion'; Expression={$_.VersionInfo.ProductVersion}},
    @{Name='FileVersion'; Expression={$_.VersionInfo.FileVersion}}
```

Sign-in, tenant or workspace selection, MFA, microphone and camera permissions,
notification preferences, and startup behavior are interactive user decisions.
Never automate them or request credentials. Respect organization policy,
application-control rules, and managed-device controls.

### macOS

Prefer the vendors' signed macOS installers. When Homebrew is already approved,
its casks provide a concise package-manager path:

```bash
brew install --cask discord slack microsoft-teams
```

Inventory existing casks and `/Applications` first, avoid duplicates, and let
the owning cask or application updater manage upgrades.

### Linux

Use Discord and Slack only from their official vendor package/repository or an
organization-approved distribution source. Microsoft does not provide a
supported Teams desktop client for Linux; use Teams on the web or install it as
a browser PWA. Do not substitute arbitrary third-party Teams wrappers.

## 11. Install Power BI Desktop on Windows

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

## 12. Install and configure Unsloth Desktop for local models

Use **Unsloth Desktop**, the official native Windows/macOS/Linux application,
as the default local-model interface. **Unsloth Studio** is the separately
installed browser-based web UI; **Unsloth Core** is the Python training library.
Installing `unsloth` with pip or running the Studio installer is not a Desktop
installation. Do not add Studio, Core, CUDA, or ROCm merely to install Desktop.

Official documentation and package catalogs checked on 2026-11-21 advertise
Desktop as **beta**, including Winget `UnslothAI.Unsloth` and Homebrew cask
`unsloth`. Disclose the beta status and confirm acceptance before installing;
do not describe it as stable. Recheck the live catalog, release assets and
platform requirements at execution time, rather than pinning today's version.

Preserve existing Lemonade installs, services, models, caches, telemetry
preferences, and client/provider configuration. Do not uninstall Lemonade,
reuse its managed backend binaries, move runtime data, change GPU drivers,
firmware, memory reservations, or power settings without separate approval.
Updating this skill alone does not authorize installing Unsloth or downloading
models. Read-only inventory must not start services or install backends.

### Inventory hardware, drivers, and usable memory

Record the exact CPU, GPU and NPU models, architecture, driver versions, free
disk space, installed RAM, OS-visible/free RAM, and dedicated/shared GPU memory.
Do not infer the CPU model from its GPU/NPU family or equate an NPU with CUDA.

On Windows:

```powershell
$cpu = Get-CimInstance Win32_Processor |
  Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors
$gpu = Get-CimInstance Win32_VideoController |
  Select-Object Name, DriverVersion, PNPDeviceID, AdapterRAM
$npu = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
  Where-Object {
    $_.FriendlyName -match 'NPU|Neural|AMD IPU|Ryzen AI'
  } |
  Select-Object Status, Class, FriendlyName, InstanceId

$npuDrivers = foreach ($device in $npu) {
  $driver = Get-PnpDeviceProperty -InstanceId $device.InstanceId `
    -KeyName 'DEVPKEY_Device_DriverVersion' -ErrorAction SilentlyContinue
  [pscustomobject]@{
    Status = $device.Status
    Name = $device.FriendlyName
    DriverVersion = $driver.Data
  }
}

$dimms = Get-CimInstance Win32_PhysicalMemory
$physicalBytes = ($dimms | Measure-Object Capacity -Sum).Sum
$computerBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
$os = Get-CimInstance Win32_OperatingSystem
[pscustomobject]@{
  PhysicalDimmGiB = [math]::Round($physicalBytes / 1GB, 2)
  ComputerSystemGiB = [math]::Round($computerBytes / 1GB, 2)
  OsVisibleGiB = [math]::Round(($os.TotalVisibleMemorySize * 1KB) / 1GB, 2)
  OsFreeGiB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 2)
}

$cpu
$gpu
$npuDrivers
$dimms | Select-Object Manufacturer, PartNumber, Capacity, Speed
```

Inspect both the physical DIMM total and OS-visible memory. AMD Variable
Graphics Memory can reserve unified memory for the iGPU: reserving 32 GB on a
64 GB system can enable larger GPU-resident models while leaving Windows only
about 32 GB visible. `Win32_OperatingSystem.TotalVisibleMemorySize` therefore
does not represent the installed DIMM total, and `AdapterRAM` is not a reliable
measure of the full unified-memory reservation. Explain this tradeoff before
any separately approved change to firmware or AMD Software memory settings.

On macOS, use `system_profiler SPHardwareDataType SPDisplaysDataType`,
`sysctl -n hw.memsize`, `vm_stat`, and `df -h`. On Linux, use `lscpu`,
`lspci -nnk`, `free -h`, and `df -h`; inspect NPU driver/firmware support when
that backend is requested. When already available, use `nvidia-smi` for
NVIDIA GPU/driver/free VRAM or `amd-smi` for AMD runtime/device information.
Do not install GPU tooling just to complete inventory; report missing evidence.

Inventory app bundles, package records, existing `unsloth` command paths, and
any Studio/Core environments before installation. A CLI's presence alone
does not establish Desktop ownership. On macOS check `brew list --cask
--versions unsloth`, `/Applications/Unsloth.app`, and user Applications; on
Linux check the distro package database and any existing AppImage or cask.
Record app version and setup status from the installed Desktop UI.

| Hardware/path | Local inference guidance |
|---|---|
| CPU only | Start with a small GGUF supported by the app; expect slower generation. CPU chat support is not proof of training support. |
| NVIDIA GPU | Check the exact GPU and driver against current Unsloth requirements; use the app-supported GPU backend and verify actual offload. Do not assume a displayed CUDA version proves a compatible installed toolkit. |
| AMD GPU | Check the exact GPU, OS and runtime against Unsloth/AMD support; use only a backend offered by the app for that device. Prior Lemonade ROCm support does not prove Unsloth compatibility. |
| Apple Silicon | The current Mac download/cask targets Apple Silicon. Use supported MLX models or GGUF/Metal and budget shared memory once, not as separate RAM plus VRAM. |
| Intel GPU/Intel Mac | Verify a supported Desktop asset and backend for the exact device. Do not assume the Apple Silicon cask runs on Intel Macs, or substitute Core/Studio silently. |
| AMD XDNA 2 NPU | The official NPU guide covers supported Ryzen AI 300/Max/400 PCs on Windows 11 or Linux x64. Use FastFlowLM-compatible Q4NX models from the NPU picker, not arbitrary GGUF/MLX files. |

For the NPU path, recheck the [official NPU prerequisites](https://unsloth.ai/docs/get-started/install/amd/amd-npu)
including drivers, firmware, Linux kernel/`amdxdna` and memlock requirements.
**Enable NPU** downloads FastFlowLM and checks drivers; obtain approval before
this one-time runtime setup. Report unmet prerequisites instead of changing
kernel, drivers or security/resource policy automatically. NPU inference does
not imply NPU fine-tuning support.

### Install or upgrade the official package

Use one installation/update owner, not duplicate Winget, direct-installer,
Homebrew, AppImage, or Python variants. An existing healthy Desktop installation
counts even if the package manager does not recognize it. Do not downgrade a
newer app just because the catalog lags its updater.

#### Windows

Inspect the live package before choosing install or upgrade:

```powershell
winget list --exact --id UnslothAI.Unsloth --source winget `
  --accept-source-agreements
winget show --exact --id UnslothAI.Unsloth --source winget `
  --accept-source-agreements
```

Confirm publisher **Unsloth AI**, official release URL, installer hash and
architecture. A network/source error is not evidence the app is absent. Only
after inventory confirms it is missing and installation is approved:

```powershell
winget install --exact --id UnslothAI.Unsloth --source winget `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

For an existing Winget-owned installation, use upgrade instead:

```powershell
winget upgrade --exact --id UnslothAI.Unsloth --source winget `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Explain any elevation prompt first. If Winget is unavailable, download the
matching installer from the [official Windows page](https://unsloth.ai/download/windows).
Check Authenticode validity and publisher, and compare any published release
checksum before running the saved file. Stop on an invalid signature/hash or
blocked source; never bypass SmartScreen or application-control policy.

#### macOS

When Homebrew is already approved, inspect its current architecture constraints:

```bash
brew info --cask unsloth
brew list --cask --versions unsloth
```

On a supported Mac, run only the appropriate operation:

```bash
brew install --cask unsloth
# For an existing cask-owned installation, upgrade instead:
brew upgrade --cask unsloth
```

Alternatively use the official `.dmg` from the [Mac download page](https://unsloth.ai/download/mac)
and drag Unsloth into Applications. Preserve code-signing/Gatekeeper checks;
never remove quarantine attributes to force launch. If no matching Intel Mac
asset exists, report Desktop unavailable for that device.

#### Linux

Use the current [official Linux download page](https://unsloth.ai/download/linux):
it lists Ubuntu/Debian `.deb`, an AppImage, and an ARM64 `.deb`. Verify the
release asset's architecture and distro requirements; do not assume the
AppImage supports ARM64 or a `.deb` works on RPM-based distributions.
Download over HTTPS, verify any published checksum/signature through the
official release source, and inspect package metadata before installation.

On compatible Debian/Ubuntu, install or upgrade the reviewed local package
through APT (replace the placeholder with its saved absolute path):

```bash
dpkg-deb --info /path/to/Unsloth-Desktop-Ubuntu.deb
sudo apt-get install /path/to/Unsloth-Desktop-Ubuntu.deb
```

For other supported distributions use the official matching AppImage and its
documented dependencies; make only that reviewed file executable and launch it
as the normal user. Do not invent signed APT/RPM repositories, convert packages,
install a second variant, or bypass sandbox/SELinux policy. Report unsupported
platforms or blocked prerequisites.

Desktop's **Settings -> General -> Check for updates** supports Windows/macOS
and Linux AppImage updates. `.deb` updates require installing the newer official
package over the existing one. Keep package-manager-owned copies on their
owning update channel; preserve app data and do not use uninstall/zap to update.

### First launch, model selection and context

Launch Desktop from the installed app, confirm its actual version, and wait for
first-run setup to finish. Review backend/dependency downloads and their disk
requirements before authorizing them. Keep telemetry, startup, credentials,
cloud providers, tools, filesystem permissions and existing client settings
unchanged unless the user requests changes. A package record is not proof that
runtime setup completed.

Choose a context size from current OS-visible free memory, model size,
quantization, KV cache, runtime overhead, free VRAM/shared memory and other
applications. Leave OS headroom; model download size is not total runtime
memory. Start with one small supported instruction/chat model and a short
context (for example 2048 only if it fits), not a fixed large model or 8192+
context for every device. Increase only after successful load and generation.

Prefer a compatible already-downloaded model. Ask before any model download,
state its size/license/source, and select the appropriate GGUF, MLX or NPU
format in **Model hub** / **Select model**. Do not automatically copy Lemonade
cache files or choose a cloud endpoint as a success-shaped fallback.

Record the actual model ID, quantization, backend/device, context and memory
use. Confirm the app reports the intended accelerator during inference; report
CPU fallback explicitly. Send a short text-only chat with tools/web search
disabled. If a load fails, surface the error, lower context/offload or choose a
smaller approved model; do not change drivers or memory policy to force success.

### Verify the local OpenAI-compatible API

Use the [official API guide](https://unsloth.ai/docs/basics/api). Keep loopback
binding and discover the actual endpoint/port from the app; do not assume
Lemonade's port or that every Desktop version exposes the same endpoints.
Ensure the listener is only `127.0.0.1` / `::1` (Windows
`Get-NetTCPConnection`, macOS `lsof -nP -iTCP -sTCP:LISTEN`, Linux `ss -ltnp`).
Do not enable LAN, bind to all interfaces, create tunnels or firewall openings.

Create a dedicated key interactively in **Settings -> API** when approved;
it is shown only once. Store it in the user's approved secret store, never
chat, screenshots, shell history, committed config or logs. Every request needs
Bearer authentication. Do not assume the unauthenticated Lemonade test applies.

The following PowerShell 7 smoke test works on all three platforms. Set the
base URI to the app's actual loopback endpoint (without `/v1`) and the model ID
to the intended loaded model. Enter the key only at the secure terminal prompt:

```powershell
$ErrorActionPreference = 'Stop'
$baseUri = [uri](Read-Host 'Unsloth loopback base URI shown in the app')
if ($baseUri.Scheme -notin @('http', 'https') -or
    $baseUri.Host -notin @('localhost', '127.0.0.1', '[::1]', '::1') -or
    $baseUri.UserInfo -or $baseUri.AbsolutePath -ne '/' -or
    $baseUri.Query -or $baseUri.Fragment) {
  throw 'Use only the actual loopback base URI without credentials or a path.'
}
$loadedModelName = Read-Host 'Exact loaded model ID'
$secret = Read-Host 'Unsloth API key' -AsSecureString
$headers = @{
  Authorization = 'Bearer ' + ([System.Net.NetworkCredential]::new('', $secret).Password)
}
try {
  $base = $baseUri.AbsoluteUri.TrimEnd('/')
  $models = Invoke-RestMethod -Uri "$base/v1/models" -Headers $headers `
    -TimeoutSec 30 -MaximumRedirection 0
  $model = $models.data | Where-Object id -eq $loadedModelName |
    Select-Object -First 1
  if (-not $model -or $model.loaded -eq $false) {
    throw 'The intended model is absent or reported as not loaded.'
  }

  $body = @{
    model = $model.id
    messages = @(
      @{ role = 'user'; content = 'Reply with exactly: unsloth-ok' }
    )
    stream = $false
    max_tokens = 128
    enable_tools = $false
  } | ConvertTo-Json -Depth 5

  $response = Invoke-RestMethod -Method Post `
    -Uri "$base/v1/chat/completions" -Headers $headers `
    -ContentType 'application/json' -Body $body `
    -TimeoutSec 180 -MaximumRedirection 0
  $content = [string]$response.choices[0].message.content
  if ($content.Trim() -ne 'unsloth-ok' -or
      $response.choices[0].finish_reason -eq 'length') {
    throw 'Inference did not complete the expected unsloth-ok reply.'
  }
  [pscustomobject]@{
    Model = $model.id
    Content = $content
  }
}
finally {
  $headers.Clear()
  $secret.Dispose()
  Remove-Variable headers, secret
}
```

Inspect the returned text: a model listing or HTTP 200 alone is not inference
verification. A reasoning-only/token-exhausted reply is incomplete; use a small
approved non-reasoning model or its documented reasoning settings and retry.
Report authentication, endpoint, loading and generation errors separately.
Do not log request headers or create persistent client/provider changes just
to test the API. If API support is unavailable, report installed/UI-operational
but API-unverified rather than installing Studio silently.

### Optional fine-tuning, not a default prerequisite

Only prepare training when requested. Verify the exact GPU, OS, driver, Python,
PyTorch and CUDA/ROCm/MLX/Intel runtime combination against the current
[requirements](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners/unsloth-requirements),
[AMD guide](https://unsloth.ai/docs/get-started/install/amd),
[Intel guide](https://unsloth.ai/docs/get-started/install/intel), and platform
guide. Desktop inference support does not prove training support.

For separately requested Core/Studio environments, use an isolated compatible
Python (current general training guidance is 3.11-3.13, not 3.14); preserve the
developer Python installations. Use vendor-specific dependency instructions,
not generic CUDA wheels on AMD. Validate accelerator operations and imports
before an approved small training run; inference memory budgets are not
training budgets. Do not download datasets/models or train automatically.

Before executing this section, recheck the [Desktop documentation](https://unsloth.ai/docs/desktop),
[Windows](https://unsloth.ai/docs/get-started/install/windows-installation),
[macOS](https://unsloth.ai/docs/get-started/install/mac),
[Linux](https://unsloth.ai/docs/get-started/install/linux), and
[update guide](https://unsloth.ai/docs/get-started/install/updating).

## 13. Install Docker

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

## 14. Windows-only virtualization, WSL 2, and Ubuntu

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

## 15. Final verification

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

For Unsloth on every supported platform, repeat section 12's package/app
version and backend checks, a successful local UI chat, and the authenticated
loopback `/v1/models` plus `/v1/chat/completions` smoke test. Record model ID,
quantization, context, device and actual generated text without exposing keys.
If installation, model download or API-key creation was not authorized, report
that stage as deferred, not operational. Leave existing Lemonade untouched.

### Windows additions

```powershell
py --list-paths
wt --version
winget list --exact --id Microsoft.PowerBI --source winget --accept-source-agreements
winget list --exact --id UnslothAI.Unsloth --source winget --accept-source-agreements
$collaborationWingetIds = @(
  'Discord.Discord',
  'SlackTechnologies.Slack',
  'Microsoft.Teams'
)
foreach ($id in $collaborationWingetIds) {
  winget list --exact --id $id --accept-source-agreements
}
$collaborationStorePackages = @('91750D7E.Slack', 'MSTeams') |
  ForEach-Object { Get-AppxPackage -Name $_ }
$collaborationStorePackages |
  Select-Object Name, Version, Architecture, PackageFullName, SignatureKind,
    Status
foreach ($package in $collaborationStorePackages) {
  $manifest = Get-AppxPackageManifest -Package $package
  foreach ($application in $manifest.Package.Applications.Application) {
    $relativeExecutable = [string]$application.Executable
    if ($relativeExecutable) {
      $executable = Join-Path $package.InstallLocation $relativeExecutable
      if (Test-Path -LiteralPath $executable) {
        Get-Item -LiteralPath $executable |
          Select-Object FullName,
            @{Name='ProductVersion'; Expression={$_.VersionInfo.ProductVersion}},
            @{Name='FileVersion'; Expression={$_.VersionInfo.FileVersion}}
      }
    }
  }
}
$collaborationWin32Executables = @(
  Get-ChildItem "$env:LOCALAPPDATA\Discord\app-*\Discord.exe" `
    -ErrorAction SilentlyContinue
  Get-Item "$env:LOCALAPPDATA\slack\slack.exe" -ErrorAction SilentlyContinue
  Get-Item "$env:ProgramFiles\Slack\slack.exe" -ErrorAction SilentlyContinue
) | Sort-Object FullName -Unique
$collaborationWin32Executables |
  Select-Object FullName,
    @{Name='ProductVersion'; Expression={$_.VersionInfo.ProductVersion}},
    @{Name='FileVersion'; Expression={$_.VersionInfo.FileVersion}}
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

Verify Unsloth's installed app version and owning update channel. For a
cask-owned copy use `brew list --cask --versions unsloth`; confirm the supported
MLX/Metal or CPU backend rather than running Windows GPU commands.

### Linux additions

```bash
cat /etc/os-release
cc --version
systemctl is-enabled docker
systemctl is-active docker
id
```

Verify Unsloth's installed app version and owning package/AppImage channel,
the exact architecture, and supported runtime/device. Do not run Windows GPU
commands or treat a missing distro package as permission to install a duplicate.

Report exact installed versions, package sources, policy restrictions, reboot
or re-login requirements, and interactive first-run steps. Distinguish
installed, configured, authenticated, and operational states. A task is not
complete until the requested tools are operational on the detected platform.
