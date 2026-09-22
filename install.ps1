[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]*$')]
    [string]$Skill
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot "skills\$Skill"
$manifest = Join-Path $source 'SKILL.md'
$destination = Join-Path $HOME ".copilot\skills\$Skill"

if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw "Skill '$Skill' was not found at '$source'."
}

$content = Get-Content -LiteralPath $manifest -Raw
if ($content -notmatch "(?s)^---\r?\nname:\s+$([regex]::Escape($Skill))\r?\n.*?\r?\n---\r?\n") {
    throw "SKILL.md has missing or invalid frontmatter for '$Skill'."
}

New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null

$staging = "$destination.new"
if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $staging -Recurse

if (Test-Path -LiteralPath $destination) {
    $backup = "$destination.backup"
    if (Test-Path -LiteralPath $backup) {
        Remove-Item -LiteralPath $backup -Recurse -Force
    }
    Move-Item -LiteralPath $destination -Destination $backup
    try {
        Move-Item -LiteralPath $staging -Destination $destination
        Remove-Item -LiteralPath $backup -Recurse -Force
    }
    catch {
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        Move-Item -LiteralPath $backup -Destination $destination
        throw
    }
}
else {
    Move-Item -LiteralPath $staging -Destination $destination
}

Write-Output "Installed '$Skill' to '$destination'."
