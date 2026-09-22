---
name: dev-machine-setup
description: >-
  Set up or repair a Windows developer machine with VS Code, Git and GitHub
  SSH, Python 3.14 and 3.13, uv, Ruff, Pyright, pre-commit-compatible tooling,
  PowerShell 7, Azure CLI and Azure PowerShell, Windows Terminal, Hyper-V,
  WSL 2 with the latest Ubuntu LTS, and Docker Desktop. Use when the user asks
  to provision, bootstrap, configure, verify, or repair a Windows dev machine.
---

# Windows developer machine setup

Provision the machine incrementally, preserve existing configuration, and verify
every installed surface. Expect administrator prompts and one reboot for
virtualization features. Never claim completion before post-reboot validation.

## Safety and interaction rules

- Ask for the Git user name, Git email, and preferred source root if not given.
  Default the source root to `C:\Users\<user>\git`.
- Before changing a tool, inventory its current version and persistent `PATH`.
- Never overwrite an existing SSH private key or request a passphrase in chat.
  Use an interactive terminal for `ssh-keygen` and `ssh-add`.
- Explain each UAC prompt immediately before invoking it.
- Do not disable TLS validation, execution policy, antivirus, application
  control, or administrator policy.
- If `files.pythonhosted.org` is blocked, use approved Winget/npm alternatives.
  Do not evade the block. Ask for an approved Python package mirror if the user
  specifically requires packages unavailable elsewhere.
- Use exact Winget IDs, accept source/package agreements, and disable
  interactive Winget prompts. Treat "already installed/no upgrade available" as
  success after independently checking the executable.
- Rebuild `$env:Path` from persistent values before verification because the
  current shell does not automatically receive installer `PATH` changes:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'Machine')
```

## 1. Inventory

Check Winget and existing tools:

```powershell
winget --version
code --version
py --list-paths
python --version
uv --version
git --version
gh --version
git lfs version
pwsh --version
az version
wsl --status
docker --version
```

Confirm the source root exists, creating it only when requested. Inspect Git
configuration and `~\.ssh` before making changes.

## 2. Core editor and Python

Install or upgrade VS Code:

```powershell
winget install --exact --id Microsoft.VisualStudioCode --scope user `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Install Python 3.14 and 3.13 side-by-side. Do not pass `--scope user` to these
Winget IDs because it can filter out the otherwise valid installer. Instead,
use Python install properties:

```powershell
$pyArgs = 'InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0 Include_doc=0 Include_tcltk=1 Include_pip=1 Shortcuts=0 SimpleInstall=1'

winget install --exact --id Python.Python.3.14 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent --override $pyArgs

winget install --exact --id Python.Python.3.13 `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent --override $pyArgs

winget install --exact --id astral-sh.uv `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Python 3.14 should remain the launcher default, while 3.13 provides compatibility
for dependencies that do not yet support 3.14.

Install VS Code extensions one at a time:

```powershell
$code = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'
$extensions = @(
  'ms-python.python',
  'ms-python.vscode-pylance',
  'charliermarsh.ruff',
  'GitHub.vscode-pull-request-github',
  'ms-vscode.vscode-node-azure-pack'
)
$extensions | ForEach-Object { & $code --install-extension $_ }
```

Do not force-install `GitHub.copilot` when Copilot Chat is built into the current
VS Code release; a forced Marketplace install can attempt to downgrade the
built-in chat extension.

Try Python tools through uv first:

```powershell
uv tool install ruff
uv tool install pyright
uv tool install pre-commit
```

If PyPI's file CDN is blocked, install policy-friendly equivalents:

```powershell
winget install --exact --id astral-sh.ruff `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent

winget install --exact --id OpenJS.NodeJS.LTS `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent

& 'C:\Program Files\nodejs\npm.cmd' install --global pyright

winget install --exact --id j178.Prek `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

`prek` is a drop-in, pre-commit-compatible runner. Do not weaken PowerShell
execution policy for npm's `.ps1` shim; verify Pyright using
`$env:APPDATA\npm\pyright.cmd` when necessary.

## 3. Git, GitHub CLI, and Git LFS

Install:

```powershell
winget install --exact --id GitHub.cli `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent

winget install --exact --id GitHub.GitLFS `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Git LFS can also upgrade Git for Windows and requests elevation. After a
successful installation:

```powershell
git lfs install --skip-repo
git config --global user.name '<git-user-name>'
git config --global user.email '<git-email>'
git config --global init.defaultBranch main
git config --global core.editor 'code --wait'
git config --global credential.helper manager
git config --global core.sshCommand 'C:/Windows/System32/OpenSSH/ssh.exe'
```

Copilot Desktop can inject private Git/gh binaries into its own process `PATH`.
Verify persistent system installations directly when versions appear stale:

```powershell
& 'C:\Program Files\Git\cmd\git.exe' --version
& 'C:\Program Files\GitHub CLI\gh.exe' --version
& 'C:\Program Files\Git LFS\git-lfs.exe' version
```

## 4. Windows OpenSSH and GitHub

Use `~\.ssh\id_ed25519_github` unless the user chooses another path. Preserve an
existing key. In an interactive terminal:

```powershell
$key = Join-Path $env:USERPROFILE '.ssh\id_ed25519_github'
New-Item -ItemType Directory -Force -Path (Split-Path $key) | Out-Null
if (-not (Test-Path -LiteralPath $key)) {
  ssh-keygen -t ed25519 -C '<git-email>' -f $key
}
```

Enable the Windows SSH agent from an elevated PowerShell:

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service -Name ssh-agent
```

Append this block to `~\.ssh\config` only if a `Host github.com` block does not
already exist:

```text
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
    AddKeysToAgent yes
```

Load the key interactively:

```powershell
ssh-add "$env:USERPROFILE\.ssh\id_ed25519_github"
```

Configure SSH signing:

```powershell
git config --global gpg.format ssh
git config --global user.signingkey '~/.ssh/id_ed25519_github.pub'
git config --global commit.gpgsign true
git config --global tag.gpgSign true
```

Authenticate GitHub and upload the public key:

```powershell
& 'C:\Program Files\GitHub CLI\gh.exe' auth login `
  --hostname github.com --git-protocol ssh --web
```

Verify with Windows OpenSSH:

```powershell
ssh-add -l
ssh -o StrictHostKeyChecking=accept-new -T git@github.com
```

GitHub's successful SSH greeting exits with status 1 because GitHub does not
provide shell access. Treat the text `You've successfully authenticated` as
success, not the exit code alone.

## 5. PowerShell and Azure tooling

Install:

```powershell
winget install --exact --id Microsoft.PowerShell `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent

winget install --exact --id Microsoft.AzureCLI `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Current PowerShell releases may be MSIX packages. Do not assume the legacy
`C:\Program Files\PowerShell\7\pwsh.exe` path. Locate the executable with:

```powershell
$pwsh = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pwsh.exe'
& $pwsh --version
```

Install Azure PowerShell from PowerShell 7:

```powershell
pwsh -NoLogo -NoProfile -Command @'
$ProgressPreference = 'SilentlyContinue'
Install-PSResource -Name Az -Repository PSGallery -Scope CurrentUser `
  -TrustRepository -Quiet -AcceptLicense
Get-Module Az -ListAvailable |
  Sort-Object Version -Descending |
  Select-Object -First 1 Name, Version
'@
```

Do not set PSGallery permanently trusted unless the user asks.

## 6. Windows Terminal, Hyper-V, WSL 2, Ubuntu, and Docker

Install Windows Terminal:

```powershell
winget install --exact --id Microsoft.WindowsTerminal `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

Check Windows edition and virtualization support. Full Hyper-V is supported on
Pro/Enterprise/Education, not Home. Do not apply unofficial Home workarounds:

```powershell
Get-CimInstance Win32_OperatingSystem |
  Select-Object Caption, Version, BuildNumber
systeminfo.exe | Select-String 'Hyper-V Requirements'
```

From elevated PowerShell, enable supported features:

```powershell
$features = @(
  'Microsoft-Hyper-V-All',
  'VirtualMachinePlatform',
  'Microsoft-Windows-Subsystem-Linux',
  'HypervisorPlatform'
)
foreach ($feature in $features) {
  $state = Get-WindowsOptionalFeature -Online -FeatureName $feature
  if ($state.State -ne 'Enabled') {
    Enable-WindowsOptionalFeature -Online -FeatureName $feature `
      -All -NoRestart | Out-Null
  }
}
bcdedit /set hypervisorlaunchtype auto
```

Keep service startup types aligned with Windows defaults while ensuring they are
not disabled:

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

Enable WSL without selecting an old default distro:

```powershell
wsl --install --no-distribution
wsl --set-default-version 2
wsl --list --online
```

Choose the highest available Ubuntu release ending in `.04` and labeled LTS.
For the September 2026 catalog this is:

```powershell
wsl --install -d Ubuntu-26.04 --no-launch
```

Install Docker Desktop and approve elevation:

```powershell
winget install --exact --id Docker.DockerDesktop `
  --accept-package-agreements --accept-source-agreements `
  --disable-interactivity --silent
```

## 7. Reboot boundary and finalization

After Hyper-V, Virtual Machine Platform, or WSL features change, stop and tell
the user a reboot is mandatory. Do not attempt to start WSL 2 or Docker before
the reboot and report their resulting virtualization error as a permanent
failure.

After reboot:

1. Launch `Ubuntu-<version>` and let the user create the Linux username and
   password interactively.
2. Set it as the default distro and confirm WSL 2:

```powershell
wsl --set-default Ubuntu-26.04
wsl --set-version Ubuntu-26.04 2
wsl --list --verbose
```

3. Start Docker Desktop, accept its terms if the user agrees, select the WSL 2
   backend, and enable integration with the Ubuntu distro.
4. Verify:

```powershell
docker version
docker info
docker run --rm hello-world
wsl -d Ubuntu-26.04 -- uname -a
wsl -d Ubuntu-26.04 -- cat /etc/os-release
```

## 8. Final verification

Run verification from a newly opened terminal:

```powershell
code --version
py -0p
python --version
uv --version
ruff --version
pyright.cmd --version
prek --version
git --version
git lfs version
gh --version
ssh-add -l
pwsh --version
az version
pwsh -NoProfile -Command 'Get-Module Az -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1 Name,Version'
wt --version
wsl --list --verbose
docker version
```

Report exact installed versions, remaining policy restrictions, whether a reboot
is pending, and any interactive first-run steps. Distinguish installed,
configured, authenticated, and operational states.
