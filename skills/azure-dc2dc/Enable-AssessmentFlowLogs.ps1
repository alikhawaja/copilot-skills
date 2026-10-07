#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidatePattern('^[0-9a-fA-F-]{36}$')][string]$TenantId,
    [string[]]$SubscriptionIds,
    [ValidatePattern('^[0-9a-fA-F-]{36}$')][string]$UserObjectId,
    [ValidateRange(1, 365)][int]$RetentionDays = 14,
    [ValidateRange(1, 90)][int]$ObservationDays = 7,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
$rgName = 'rg-azure-migration-assessment'
$roleName = 'Azure Migration Flow Log Operator'
if ($RetentionDays -le $ObservationDays) {
    throw 'RetentionDays must exceed ObservationDays so early logs remain available for analysis.'
}

function Get-AzJson {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $output = & az @Arguments --only-show-errors --output json
    if ($LASTEXITCODE -ne 0) { throw "Azure CLI failed: az $($Arguments -join ' ')" }
    if (-not $output) { throw "Azure CLI returned no data: az $($Arguments -join ' ')" }
    return ConvertFrom-Json -InputObject ($output | Out-String)
}

function New-Name {
    param([string]$Prefix, [string]$Value, [int]$Length = 18)
    $bytes = [System.Security.Cryptography.SHA256]::HashData(
        [System.Text.Encoding]::UTF8.GetBytes($Value.ToLowerInvariant()))
    return $Prefix + ([Convert]::ToHexString($bytes).ToLowerInvariant().Substring(0, $Length))
}

function Ensure-Assignment {
    param([string]$Subscription, [string]$Scope, [string]$Role, [string]$Principal)
    $assigned = @(Get-AzJson @('role', 'assignment', 'list', '--scope', $Scope,
        '--subscription', $Subscription))
    if ($assigned | Where-Object {
        $_.scope -eq $Scope -and $_.principalId -eq $Principal -and
        (($_.roleDefinitionId -split '/')[-1] -eq $Role -or $_.roleDefinitionName -eq $Role)
    }) { return }
    $null = Get-AzJson @('role', 'assignment', 'create', '--assignee-object-id',
        $Principal, '--assignee-principal-type', 'User', '--role', $Role, '--scope',
        $Scope, '--subscription', $Subscription)
    Write-Host "Assigned $Role at $Scope"
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Install Azure CLI and sign in to the customer tenant before running this script.'
}
$accounts = @(Get-AzJson @('account', 'list', '--all'))
if (-not $TenantId) { $TenantId = Read-Host 'Customer tenant GUID' }
if ($TenantId -notmatch '^[0-9a-fA-F-]{36}$') { throw 'Enter a tenant GUID.' }
$visible = @($accounts | Where-Object { $_.tenantId -eq $TenantId -and $_.state -eq 'Enabled' })
if (-not $visible.Count) { throw "No enabled subscriptions visible in tenant $TenantId." }
Write-Host "`nVisible subscriptions in selected tenant:"
$visible | ForEach-Object { Write-Host "  $($_.name) [$($_.id)]" }
if (-not $SubscriptionIds) {
    $SubscriptionIds = @((Read-Host 'Comma-separated subscription GUIDs to assess').Split(',') |
        ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$SubscriptionIds = @($SubscriptionIds | Select-Object -Unique)
if (-not $SubscriptionIds.Count) { throw 'Select at least one subscription.' }
foreach ($id in $SubscriptionIds) {
    if ($id -notmatch '^[0-9a-fA-F-]{36}$' -or $id -notin $visible.id) {
        throw "Subscription $id is not visible in tenant $TenantId."
    }
}
if (-not $UserObjectId) { $UserObjectId = Read-Host 'Microsoft Entra user object ID (GUID) to grant access' }
if ($UserObjectId -notmatch '^[0-9a-fA-F-]{36}$') { throw 'Enter a user object ID GUID, not an email address.' }

# Inventory first. No Azure write occurs before the plan and explicit confirmation.
$plans = @()
foreach ($id in $SubscriptionIds) {
    $vnets = @(Get-AzJson @('network', 'vnet', 'list', '--subscription', $id))
    $groups = @(Get-AzJson @('group', 'list', '--subscription', $id))
    $stores = @(Get-AzJson @('storage', 'account', 'list', '--subscription', $id))
    $watchers = @(Get-AzJson @('network', 'watcher', 'list', '--subscription', $id))
    $workspaces = @(Get-AzJson @('monitor', 'log-analytics', 'workspace', 'list', '--subscription', $id))
    $provider = Get-AzJson @('provider', 'show', '--namespace', 'Microsoft.Insights',
        '--subscription', $id)
    if ($provider.registrationState -notin @('Registered', 'NotRegistered', 'Registering')) {
        throw "Unexpected Microsoft.Insights provider state in $id`: $($provider.registrationState)."
    }
    if (-not $vnets.Count) { throw "No VNets in $id; no flow logs will be created." }
    foreach ($vnet in $vnets) {
        if (-not $vnet.id -or -not $vnet.location) {
            throw "VNet inventory in $id has a missing ID or region; no changes made."
        }
    }
    $rg = @($groups | Where-Object name -EQ $rgName)
    $location = $vnets[0].location
    if ($rg.Count) { $location = $rg[0].location }
    $regionPlans = @()
    foreach ($region in @($vnets.location | Select-Object -Unique)) {
        $regionVnets = @($vnets | Where-Object location -EQ $region)
        $storageName = New-Name 'stam' "$id/$region" 20
        $storage = @($stores | Where-Object name -EQ $storageName)
        if ($storage.Count -and ($storage[0].resourceGroup -ne $rgName -or
            $storage[0].location -ne $region -or $storage[0].sku.name -ne 'Standard_LRS' -or
            $storage[0].allowSharedKeyAccess -eq $false)) {
            throw "Storage name $storageName exists outside the expected assessment RG, region or SKU."
        }
        $watcher = @($watchers | Where-Object location -EQ $region)
        if ($watcher.Count -gt 1) { throw "Unexpected multiple Network Watchers in $id/$region." }
        $existingLogs = @()
        if ($watcher.Count) {
            $existingLogs = @(Get-AzJson @('network', 'watcher', 'flow-log', 'list',
                '--location', $region, '--subscription', $id))
        }
        $missing = @()
        $reused = @()
        $reenable = @()
        $existingLogStores = @()
        foreach ($vnet in $regionVnets) {
            $match = @($existingLogs | Where-Object {
                $_.targetResourceId -eq $vnet.id -or $_.properties.targetResourceId -eq $vnet.id
            })
            if ($match.Count -gt 1) { throw "Multiple flow logs target $($vnet.id); resolve manually." }
            if ($match.Count) {
                $existingStore = $match[0].storageId
                if (-not $existingStore) { $existingStore = $match[0].properties.storageId }
                if (-not $existingStore) { throw "No storage destination for existing flow log targeting $($vnet.id)." }
                $existingSubscription = ($existingStore -split '/')[2]
                if ($existingSubscription -notin $SubscriptionIds) {
                    throw "Existing log storage $existingStore is outside selected subscriptions; arrange separate access."
                }
                $existingLogStores += $existingStore
                if ($match[0].enabled -eq $true -or $match[0].properties.enabled -eq $true) {
                    $reused += $vnet
                } else {
                    if (-not $match[0].name) { throw "Disabled flow log targeting $($vnet.id) has no name." }
                    $reenable += [pscustomobject]@{ VNet = $vnet; FlowLog = $match[0] }
                }
            } else { $missing += $vnet }
        }
        $regionPlans += [pscustomobject]@{
            Region = $region; StorageName = $storageName; Storage = $storage
            Watcher = $watcher; Missing = $missing; Reused = $reused; Reenable = $reenable
            ExistingLogStores = @($existingLogStores | Select-Object -Unique)
        }
    }
    $plans += [pscustomobject]@{
        Subscription = $id; ResourceGroupLocation = $location; Group = $rg
        Regions = $regionPlans; Workspaces = $workspaces
        InsightsState = $provider.registrationState
    }
}

$newCount = @($plans | ForEach-Object { $_.Regions } | ForEach-Object { $_.Missing }).Count
$reenableCount = @($plans | ForEach-Object { $_.Regions } | ForEach-Object { $_.Reenable }).Count
$enableCount = $newCount + $reenableCount
Write-Host "`nPLAN - No changes have been made."
Write-Host "Tenant: $TenantId; selected subscriptions: $($SubscriptionIds -join ', ')"
Write-Host "Assignee (user object ID): $UserObjectId"
Write-Host "For EVERY VNet in these subscriptions, reuse enabled logs or enable missing VNet flow logs."
foreach ($p in $plans) {
    Write-Host "`nSubscription $($p.Subscription): RG $rgName ($($p.ResourceGroupLocation))"
    Write-Host "  Microsoft.Insights provider: $($p.InsightsState)$(if ($p.InsightsState -ne 'Registered') { ' (register/wait after confirmation)' })"
    foreach ($r in $p.Regions) {
        Write-Host "  $($r.Region): $($r.Missing.Count) new, $($r.Reenable.Count) disabled to re-enable, $($r.Reused.Count) already enabled"
        if ($r.Missing.Count) {
            Write-Host "    New log storage: $($r.StorageName) (Standard_LRS, same region; create if absent)"
            Write-Host "    Network Watcher: $(if ($r.Watcher.Count) { $r.Watcher[0].name } else { 'create in assessment RG' })"
        }
        foreach ($storeId in $r.ExistingLogStores) { Write-Host "    Reused-log read access: $storeId" }
        foreach ($v in $r.Missing) { Write-Host "    ENABLE: $($v.id)" }
        foreach ($entry in $r.Reenable) {
            Write-Host "    RE-ENABLE EXISTING $($entry.FlowLog.name): $($entry.VNet.id) (preserve its storage and retention)"
        }
        foreach ($v in $r.Reused) { Write-Host "    REUSE: $($v.id)" }
    }
    Write-Host "  Log Analytics Reader on $($p.Workspaces.Count) workspaces; Reader on subscription."
}
Write-Host "Create/reuse $rgName in each selected subscription; new storage only in regions requiring new logs."
Write-Host "Create one custom role and assign it only at Network Watcher and assessment storage-account scopes."
Write-Host 'That role includes storage listKeys/SAS permissions on the named assessment storage accounts: it can expose their account credentials.'
Write-Host "Assign Storage Blob Data Reader on new/existing log storage accounts and Log Analytics Reader on listed workspaces."
Write-Host "Requested observation window: $ObservationDays day(s); NEW logs retain blobs for $RetentionDays day(s). Existing logs keep their settings."
Write-Host 'Observation and disabling logs are NOT automated: arrange ingestion checks, analysis, and cleanup after assessment.'
Write-Host "Network Watcher ingestion and storage incur usage-based charges; exact cost depends on traffic."
Write-Host "Storage is created with anonymous blob access disabled and HTTPS required; confirm network/security policy permits it."
Write-Host "Provisional added time: $($enableCount * 15)-$($enableCount * 30) minutes setup/validation"
Write-Host "  + $ObservationDays day(s) observation + $($enableCount * 30)-$($enableCount * 60) minutes initial analysis."
Write-Host "This does not grant access to external appliances, private application configuration, or workspaces outside the selected subscriptions."
Write-Host "If a step fails, earlier changes are NOT rolled back. Do not rerun before reviewing the partial state."
if ($PlanOnly) { return }
$confirmation = Read-Host "Type ENABLE ALL $enableCount VNETS to create resources, assign roles and enable logs"
if ($confirmation -cne "ENABLE ALL $enableCount VNETS") { throw 'Confirmation not given; no Azure changes made.' }

$role = @{
    Name = $roleName; IsCustom = $true
    Description = 'Assessment VNet flow log operations and scoped storage authorization'
    Actions = @(
        'Microsoft.Network/networkWatchers/read',
        'Microsoft.Network/networkWatchers/flowLogs/read',
        'Microsoft.Network/networkWatchers/flowLogs/write',
        'Microsoft.Network/networkWatchers/configureFlowLog/action',
        'Microsoft.Network/networkWatchers/queryFlowLogStatus/action',
        'Microsoft.Storage/storageAccounts/read',
        'Microsoft.Storage/storageAccounts/listServiceSas/action',
        'Microsoft.Storage/storageAccounts/listAccountSas/action',
        'Microsoft.Storage/storageAccounts/listKeys/action'
    )
    NotActions = @(); DataActions = @(); NotDataActions = @()
    AssignableScopes = @($SubscriptionIds | ForEach-Object { "/subscriptions/$_" })
}
$existingRole = @(Get-AzJson @('role', 'definition', 'list', '--name', $roleName,
    '--subscription', $SubscriptionIds[0]))
if ($existingRole.Count) {
    $actions = @($existingRole[0].permissions[0].actions | Sort-Object)
    if ($existingRole[0].roleType -ne 'CustomRole' -or
        @($existingRole[0].permissions).Count -ne 1 -or
        ($actions -join '|') -ne ((@($role.Actions | Sort-Object)) -join '|') -or
        @($existingRole[0].permissions[0].notActions).Count -or
        @($existingRole[0].permissions[0].dataActions).Count -or
        @($existingRole[0].permissions[0].notDataActions).Count -or
        @($role.AssignableScopes | Where-Object { $_ -notin $existingRole[0].assignableScopes }).Count) {
        throw "Existing role '$roleName' does not match; no role was modified."
    }
    $roleId = $existingRole[0].name
} else {
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("migration-role-" + [guid]::NewGuid() + '.json')
    try {
        $role | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temp -Encoding utf8
        $created = Get-AzJson @('role', 'definition', 'create', '--role-definition', $temp,
            '--subscription', $SubscriptionIds[0])
        $roleId = $created.name
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp }
    }
}
if (-not $roleId) { throw 'Could not resolve the custom role ID.' }
foreach ($p in $plans) {
    $id = $p.Subscription
    if ($p.InsightsState -ne 'Registered') {
        $null = Get-AzJson @('provider', 'register', '--namespace', 'Microsoft.Insights',
            '--wait', '--subscription', $id)
        $registered = Get-AzJson @('provider', 'show', '--namespace', 'Microsoft.Insights',
            '--subscription', $id)
        if ($registered.registrationState -ne 'Registered') {
            throw "Microsoft.Insights registration did not complete in $id."
        }
    }
    if (-not $p.Group.Count) {
        $null = Get-AzJson @('group', 'create', '--name', $rgName,
            '--location', $p.ResourceGroupLocation, '--subscription', $id)
    }
    Ensure-Assignment $id "/subscriptions/$id" 'Reader' $UserObjectId
    foreach ($workspace in $p.Workspaces) {
        Ensure-Assignment $id $workspace.id 'Log Analytics Reader' $UserObjectId
    }
    foreach ($r in $p.Regions) {
        foreach ($storeId in $r.ExistingLogStores) {
            $storeSubscription = ($storeId -split '/')[2]
            Ensure-Assignment $storeSubscription $storeId 'Storage Blob Data Reader' $UserObjectId
        }
        if (-not $r.Missing.Count -and -not $r.Reenable.Count) { continue }
        if (-not $r.Watcher.Count) {
            $null = Get-AzJson @('network', 'watcher', 'configure', '--locations', $r.Region,
                '--enabled', 'true', '--resource-group', $rgName, '--subscription', $id)
            $r.Watcher = @(Get-AzJson @('network', 'watcher', 'list', '--subscription', $id) |
                Where-Object location -EQ $r.Region)
            if ($r.Watcher.Count -ne 1) { throw "Network Watcher was not created in $id/$($r.Region)." }
        }
        Ensure-Assignment $id $r.Watcher[0].id $roleId $UserObjectId
        foreach ($entry in $r.Reenable) {
            $null = Get-AzJson @('network', 'watcher', 'flow-log', 'update', '--name',
                $entry.FlowLog.name, '--location', $r.Region, '--enabled', 'true',
                '--subscription', $id)
            $flowLog = Get-AzJson @('network', 'watcher', 'flow-log', 'show',
                '--name', $entry.FlowLog.name, '--location', $r.Region, '--subscription', $id)
            if ($flowLog.enabled -ne $true -or $flowLog.targetResourceId -ne $entry.VNet.id) {
                throw "Existing flow log not confirmed enabled for $($entry.VNet.id)."
            }
            Write-Host "Re-enabled $($entry.FlowLog.name) for $($entry.VNet.id)"
        }
        if (-not $r.Missing.Count) { continue }
        if (-not $r.Storage.Count) {
            $storage = Get-AzJson @('storage', 'account', 'create', '--name', $r.StorageName,
                '--resource-group', $rgName, '--location', $r.Region, '--sku', 'Standard_LRS',
                '--kind', 'StorageV2', '--https-only', 'true', '--min-tls-version', 'TLS1_2',
                '--allow-blob-public-access', 'false', '--subscription', $id)
            $r.Storage = @($storage)
        }
        $storageId = $r.Storage[0].id
        if (-not $storageId) { throw "Could not resolve assessment storage ID in $id/$($r.Region)." }
        Ensure-Assignment $id $storageId $roleId $UserObjectId
        Ensure-Assignment $id $storageId 'Storage Blob Data Reader' $UserObjectId
        foreach ($v in $r.Missing) {
            $logName = New-Name 'fl' $v.id 24
            $null = Get-AzJson @('network', 'watcher', 'flow-log', 'create', '--name',
                $logName, '--location', $r.Region, '--vnet', $v.id, '--storage-account',
                $storageId, '--retention', "$RetentionDays", '--traffic-analytics', 'false',
                '--enabled', 'true', '--subscription', $id)
            $flowLog = Get-AzJson @('network', 'watcher', 'flow-log', 'show',
                '--name', $logName, '--location', $r.Region, '--subscription', $id)
            if ($flowLog.enabled -ne $true -or $flowLog.targetResourceId -ne $v.id) {
                throw "Flow log not confirmed enabled for $($v.id); inspect $logName (enabled=$($flowLog.enabled), target=$($flowLog.targetResourceId))."
            }
            Write-Host "Enabled $logName for $($v.id)"
        }
    }
}
Write-Host 'Setup complete. Check first log ingestion and assigned log-data access; observe for the agreed window and arrange disabling newly created logs when done.'
