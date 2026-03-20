<#
.SYNOPSIS
    Installeert Claude skills naar ~/.claude/skills/

.DESCRIPTION
    Werkt zowel lokaal als remote (via irm | iex).
    Remote: downloadt skills rechtstreeks van GitHub.
    Lokaal:  kopieert vanuit de lokale repo map.

.PARAMETER Skills
    Selecteer specifieke skills (kommagescheiden). Standaard: alle skills.

.EXAMPLE
    # One-liner voor collega's (geen git clone nodig):
    irm https://raw.githubusercontent.com/RobinCert/claude-skills/master/install.ps1 | iex

    # Lokaal, alleen specifieke skills:
    .\install.ps1 -Skills "ms365-tenant-manager,senior-devops"
#>
param(
    [string]$Skills = ""
)

$ErrorActionPreference = "Stop"

$repo      = "RobinCert/claude-skills"
$branch    = "master"
$apiBase   = "https://api.github.com/repos/$repo/contents"
$rawBase   = "https://raw.githubusercontent.com/$repo/$branch"
$skillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$isRemote  = ($PSScriptRoot -eq "")

Write-Host ""
Write-Host "Claude Skills Installer" -ForegroundColor Cyan
Write-Host "Doel: $skillsDir" -ForegroundColor Gray
if ($isRemote) {
    Write-Host "Bron: github.com/$repo" -ForegroundColor Gray
} else {
    Write-Host "Bron: lokale map" -ForegroundColor Gray
}
Write-Host ""

# ─── Skills directory aanmaken indien nodig ───────────────────────────────────
if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir | Out-Null
}

# ─── Beschikbare skills ophalen ───────────────────────────────────────────────
if ($isRemote) {
    # GitHub API: lijst van mappen in de repo root
    $headers   = @{ "User-Agent" = "claude-skills-installer" }
    $contents  = Invoke-RestMethod -Uri $apiBase -Headers $headers
    $allSkills = $contents | Where-Object { $_.type -eq "dir" -and $_.name -notmatch "^\." }
} else {
    $allSkills = Get-ChildItem $PSScriptRoot -Directory |
        Where-Object { Test-Path "$($_.FullName)\SKILL.md" } |
        ForEach-Object { [PSCustomObject]@{ name = $_.Name; localPath = $_.FullName } }
}

# ─── Filter op gevraagde skills ───────────────────────────────────────────────
if ($Skills) {
    $filter    = $Skills -split "," | ForEach-Object { $_.Trim() }
    $allSkills = $allSkills | Where-Object { $filter -contains $_.name }
}

if (-not $allSkills) {
    Write-Host "Geen skills gevonden om te installeren." -ForegroundColor Yellow
    exit 0
}

# ─── Installeren ──────────────────────────────────────────────────────────────
foreach ($skill in $allSkills) {
    $dest   = Join-Path $skillsDir $skill.name
    $label  = if (Test-Path $dest) { "[UPDATE]" } else { "[NIEUW ]" }
    $color  = if (Test-Path $dest) { "Yellow" }  else { "Green" }
    Write-Host "  $label $($skill.name)" -ForegroundColor $color

    if ($isRemote) {
        # Bestanden in de skill-map ophalen via GitHub API
        $skillFiles = Invoke-RestMethod -Uri "$apiBase/$($skill.name)" -Headers $headers

        # Subdirectories recursief ook ophalen
        $queue = [System.Collections.Generic.Queue[object]]::new()
        foreach ($f in $skillFiles) { $queue.Enqueue($f) }

        while ($queue.Count -gt 0) {
            $item     = $queue.Dequeue()
            $relPath  = $item.path -replace "^$($skill.name)/", ""
            $localDst = Join-Path $dest $relPath.Replace("/", "\")

            if ($item.type -eq "dir") {
                New-Item -ItemType Directory -Path $localDst -Force | Out-Null
                $sub = Invoke-RestMethod -Uri $item.url -Headers $headers
                foreach ($s in $sub) { $queue.Enqueue($s) }
            } else {
                $dir = Split-Path $localDst
                if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir -Force | Out-Null }
                Invoke-WebRequest -Uri "$rawBase/$($item.path)" -OutFile $localDst -UseBasicParsing
            }
        }
    } else {
        Copy-Item -Path $skill.localPath -Destination $dest -Recurse -Force
    }
}

Write-Host ""
Write-Host "Klaar — herstart Claude om de skills te activeren." -ForegroundColor Cyan
