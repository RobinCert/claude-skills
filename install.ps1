<#
.SYNOPSIS
    Installeert Claude skills naar ~/.claude/skills/

.DESCRIPTION
    Kopieert alle skill-mappen uit deze repo naar de lokale Claude skills directory.
    Na installatie zijn de skills automatisch beschikbaar in elke Claude sessie.

.PARAMETER Skills
    Selecteer specifieke skills om te installeren (kommagescheiden).
    Standaard: alle skills in deze map.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Skills "ms365-tenant-manager,senior-devops"
#>
param(
    [string]$Skills = ""
)

$ErrorActionPreference = "Stop"

$skillsDir  = Join-Path $env:USERPROFILE ".claude\skills"
$sourceDir  = $PSScriptRoot
$allSkills  = Get-ChildItem $sourceDir -Directory | Where-Object { Test-Path "$($_.FullName)\SKILL.md" }

if ($Skills) {
    $filter   = $Skills -split "," | ForEach-Object { $_.Trim() }
    $allSkills = $allSkills | Where-Object { $filter -contains $_.Name }
}

if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir | Out-Null
    Write-Host "Map aangemaakt: $skillsDir"
}

Write-Host ""
Write-Host "Claude Skills Installer" -ForegroundColor Cyan
Write-Host "Doel: $skillsDir" -ForegroundColor Gray
Write-Host ""

foreach ($skill in $allSkills) {
    $dest = Join-Path $skillsDir $skill.Name
    if (Test-Path $dest) {
        Write-Host "  [UPDATE] $($skill.Name)" -ForegroundColor Yellow
    } else {
        Write-Host "  [NIEUW ] $($skill.Name)" -ForegroundColor Green
    }
    Copy-Item -Path $skill.FullName -Destination $dest -Recurse -Force
}

Write-Host ""
Write-Host "Klaar — herstart Claude om de skills te activeren." -ForegroundColor Cyan
