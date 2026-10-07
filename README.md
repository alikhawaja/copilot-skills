# Copilot skills

Reusable skills for GitHub Copilot.

## Available skills

### `azure-dc2dc`

Plans and documents an Azure data-center-to-data-center or cross-region
migration by discovered workload. The workflow covers authenticated, read-only
discovery, an estate overview and shared landing zone, workload dependencies,
read-only dependency analysis from effective firewall/NSG/WAF/appliance
policies, time-bounded traffic logs, and sanitized application configuration,
source SKU and destination-allocation workbooks, monthly actual-cost reporting,
design decisions, Microsoft program alignment, and final packages containing
Excel workbooks, document PDFs, and a PPTX/PDF presentation. Editable Markdown
and Mermaid sources live in `assets`, while rendered diagrams live in `images`.
When VMs are present, the skill checks VNet flow-log coverage and permissions
early, discloses gaps or a per-VNet capture/time/cost plan, and requires explicit
approval before enabling any logging.

**At the start of a migration assessment:** VM dependency discovery may miss
traffic if VNet flow logs are absent or the discovery identity lacks access.
After confirming the tenant and selected subscriptions, the skill checks VM
coverage and effective permissions and reports the named gaps before detailed
analysis. The optional customer-run
[assessment flow-log script](https://raw.githubusercontent.com/alikhawaja/copilot-skills/main/skills/azure-dc2dc/Enable-AssessmentFlowLogs.ps1)
previews **every VNet in explicitly selected subscriptions** before creating
assessment resources, assigning scoped access to a specified Entra user object
ID, and enabling missing flow logs. A customer administrator can download and
review the script, then run these commands in PowerShell 7 from the download
directory (with Azure CLI installed):

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/alikhawaja/copilot-skills/main/skills/azure-dc2dc/Enable-AssessmentFlowLogs.ps1' -OutFile '.\Enable-AssessmentFlowLogs.ps1'
# Review the saved script before running it.
az login --tenant 00000000-0000-0000-0000-000000000000 # Replace with the customer tenant GUID
pwsh -File .\Enable-AssessmentFlowLogs.ps1 -PlanOnly
# Only after reviewing the full plan and obtaining approval:
pwsh -File .\Enable-AssessmentFlowLogs.ps1
```

The script prompts for the tenant GUID, **selected subscription GUIDs** and the
assignee's Entra **user object ID** (not email). Check the plan's full VNet list,
assessment resources, role scopes, charges, observation window, retention and
cleanup arrangement; execution requires typing `ENABLE ALL <count> VNETS`.
`-PlanOnly` makes no Azure changes. The administrator needs permission to create
resource groups, storage accounts, custom role definitions and assignments,
provider registrations, Network Watcher resources, and flow logs. It reuses
existing enabled flow logs, creates `rg-azure-migration-assessment` per selected
subscription and same-region storage where new logging is needed, and requests
explicit confirmation of the full plan before any write. New logs are **not** stopped
automatically; budget for usage-based logging and storage charges and arrange
cleanup after the observation period. Existing disabled VNet logs are listed
for re-enablement with their storage and retention preserved; storage outside
the selected subscriptions stops the script for separate access planning. It
grants Reader at selected subscription scope, Log Analytics Reader at discovered
workspace scope, Storage Blob Data Reader on the identified flow-log storage
accounts, and its embedded custom operator role only on the relevant Network
Watcher and assessment storage
resources. Vendor appliances, external workspaces, and secret-bearing app
configuration require separately approved access.

### `dev-machine-setup`

Sets up or repairs a Windows, macOS, or Linux developer machine with:

- VS Code and development extensions
- The latest stable .NET SDK, C# Dev Kit, and native C/C++ build tools
- Git, GitHub CLI, Git LFS, OpenSSH, and SSH signing
- GitHub Copilot CLI
- Python 3.14 and 3.13, uv, Ruff, Pyright, and pre-commit-compatible tooling
- PowerShell 7, Azure CLI, and Azure PowerShell
- Docker Desktop on Windows/macOS or Docker Engine on Linux
- Official Windows 11 compact Explorer context-menu integration, Visual Studio
  Build Tools, Windows Terminal, Hyper-V, WSL 2, and Ubuntu LTS on Windows

The workflow preserves existing credentials, respects enterprise security
policy, explains elevation prompts, and verifies each installation.

## Install

Run either installer from a cloned copy of this repository.

PowerShell 7 on Windows, macOS, or Linux:

```powershell
.\install.ps1 -Skill azure-dc2dc
.\install.ps1 -Skill dev-machine-setup
```

macOS or Linux:

```bash
./install.sh azure-dc2dc
./install.sh dev-machine-setup
```

Or copy the directory manually on any platform:

```powershell
Copy-Item -Recurse -Force `
  .\skills\azure-dc2dc `
  "$HOME\.copilot\skills\azure-dc2dc"

Copy-Item -Recurse -Force `
  .\skills\dev-machine-setup `
  "$HOME\.copilot\skills\dev-machine-setup"
```

```bash
cp -R ./skills/azure-dc2dc "$HOME/.copilot/skills/"
cp -R ./skills/dev-machine-setup "$HOME/.copilot/skills/"
```

Restart GitHub Copilot after installing or updating a skill.

## Update

Pull the desired tagged release and rerun the installer:

```powershell
git pull --ff-only
.\install.ps1 -Skill azure-dc2dc
.\install.ps1 -Skill dev-machine-setup
```

Or:

```bash
git pull --ff-only
./install.sh azure-dc2dc
./install.sh dev-machine-setup
```

## Security

Review `SKILL.md` and any referenced scripts before installation. Skills can
instruct an agent to execute commands with the same permissions as the user.
This repository contains no credentials or machine-specific secrets.

## License

Licensed under the [MIT License](LICENSE).
