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
Before findings review and final publication, the skill reconciles named
cross-workload dependencies across the evidence register, both workload dossiers,
overview and diagrams. It also traces each material design issue from observed
evidence to a concrete recommendation, approval state and affected workload
decision; unresolved gaps remain visible rather than being treated as resolved.
After confirming the account, tenant and subscriptions, the skill first checks
read-only permissions to access existing VNet flow logs. It reports **permissions
found**, missing or unverified for the identified scopes, without starting flow
discovery or asking to enable logging. The assessment continues in all cases.
When VM dependencies are investigated later, the skill identifies flow-log
coverage, asks whether to analyze the available traffic, and requests separate
approval before creating or re-enabling logs. Missing evidence leaves affected
VM dependencies explicitly unverified. The optional customer-run
[assessment flow-log script](https://raw.githubusercontent.com/alikhawaja/copilot-skills/main/skills/azure-dc2dc/Enable-AssessmentFlowLogs.ps1)
offers **GrantAccess** (the default) or **EnableFlowLogs** for every VNet in
explicitly selected subscriptions. A customer administrator can download and
review the script, then run these commands in PowerShell 7 from the download
directory (with Azure CLI installed):

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/alikhawaja/copilot-skills/main/skills/azure-dc2dc/Enable-AssessmentFlowLogs.ps1' -OutFile '.\Enable-AssessmentFlowLogs.ps1'
# Review the saved script before running it.
az login --tenant 00000000-0000-0000-0000-000000000000 # Replace with the customer tenant GUID
pwsh -File .\Enable-AssessmentFlowLogs.ps1 -Mode GrantAccess -PlanOnly
# Only after reviewing the read-access plan and obtaining approval:
pwsh -File .\Enable-AssessmentFlowLogs.ps1 -Mode GrantAccess
# For separate, customer-approved all-VNet logging, preview its plan first:
pwsh -File .\Enable-AssessmentFlowLogs.ps1 -Mode EnableFlowLogs -PlanOnly
# After separate logging approval:
pwsh -File .\Enable-AssessmentFlowLogs.ps1 -Mode EnableFlowLogs
```

The script prompts for the tenant GUID, **selected subscription GUIDs** and the
assignee's Entra **user object ID** (not email). Check the plan's full VNet list,
assessment resources, role scopes, charges, observation window, retention and
cleanup arrangement. `-PlanOnly` makes no Azure changes. GrantAccess requires
typing `GRANT READ ACCESS TO <count> SUBSCRIPTIONS`; it grants subscription
Reader and data-reader access on identified, in-scope existing log destinations
(and relevant Traffic Analytics workspaces), without creating a custom role,
resources or logs. External destinations are reported as unresolved gaps.
EnableFlowLogs requires typing `ENABLE ALL <count> VNETS`. For that mode the
administrator needs permission to create
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
- Explorer integration, Visual Studio Build Tools, Windows Terminal, Hyper-V,
  WSL 2, and Ubuntu LTS on Windows

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
