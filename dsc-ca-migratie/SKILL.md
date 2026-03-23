---
name: dsc-ca-migratie
description: >
  DSC CA migratie workflow -- analyseert overlap tussen bestaande tenant CA policies en DSC baseline policies,
  en zet exclusions over naar de DSC baseline. Uitsluitend voor DSC-klanten (WSR, HZN, RGV).
  Trigger bij: "CA migratie analyseren", "overlap analyse CA", "welke CA policies overlappen",
  "exclusions doorsturen naar DSC baseline", "CA overgang plannen", "CA analyse voor WSR/HZN/RGV",
  "carryover exclusions", "bestaande CA policies vergelijken met DSC baseline",
  "similarity score CA policies", of wanneer "overlap", "carryover" of "migratie" samen met
  "CA" of "Conditional Access" en een DSC-klant voorkomen.
  Niet triggeren bij: CarePilot, Vertimart, Intune baseline, MDM, device compliance,
  of enige combinatie met CarePilot-klanten. Ook niet triggeren bij de reguliere CA go-live
  fases (Phase 1-5) die onder dsc-ca-baseline vallen.
---

# DSC CA Migratie — Overlap Analyse en Carryover Skill

Scope: analyse en migratie van BESTAANDE tenant CA policies naar de DSC baseline.
Dit is een aparte workflow bovenop de reguliere Phase 1-5 go-live (dsc-ca-baseline skill).

---

## Setup — automatisch uitvoeren bij aanvang

**Controleer altijd als eerste of de scripts op disk staan. Als een script ontbreekt, schrijf het direct vanuit de embedded scripts onderaan dit bestand. De gebruiker hoeft hier niets voor te doen.**

Verwachte paden:
- `C:\Drop\DSC\Scripts\Template\Analyze-CaMigratie.ps1`
- `C:\Drop\DSC\Scripts\Template\Apply-CaExclusionCarryover.ps1`
- `C:\Drop\DSC\Scripts\Run-CaMigratie.ps1`

Aanpak:
1. Check of `C:\Drop\DSC\Scripts\Template\` en `C:\Drop\DSC\Scripts\` bestaan — maak aan indien nodig
2. Check elk script — als het ontbreekt, schrijf het vanuit de embedded code hieronder
3. Meld wat je hebt aangemaakt ("Scripts staan klaar op disk.")
4. Ga daarna direct door met de gevraagde taak

---

## Klant config aanmaken (als die nog niet bestaat)

Als er geen `klant-config.json` bestaat voor de gevraagde klant:
1. Vraag: klantnaam, klantcode (bijv. WSR), tenant ID, contactpersoon naam
2. Maak map `C:\Drop\DSC\Klanten\{CODE} - {Naam}\` aan
3. Schrijf `klant-config.json` op basis van het template onderaan dit bestand
4. Meld het pad en ga door

---

## Bekende DSC-klanten

| Klant | Code | Tenant ID | Config |
|---|---|---|---|
| Woonstad Rotterdam | WSR | f4cd4ee9-43a6-4256-a5e0-016c044746c8 | C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json |
| Gemeente Huizen | HZN | bc49eac0-d8da-4ed9-b328-91c793d8b02e | C:\Drop\DSC\Klanten\HZN - Gemeente Huizen\klant-config.json |
| Regio Gooi en Vechtstreek | RGV | 3d4f9081-0beb-452f-a8cf-7203e3681edc | C:\Drop\DSC\Klanten\RGV - Regio Gooi en Vechtstreek\klant-config.json |

---

## Workflow overzicht (2 stappen)

### Stap 1: Analyse (Analyze-CaMigratie.ps1) — geen PIM nodig
- Haalt ALLE CA policies op uit de tenant (read-only)
- Classificeert: DSC baseline (^CA[DLUP]\d{3}) vs bestaand vs workshop
- Berekent similarity scores per featureset (gewogen, 14 features, Jaccard scoring)
- Genereert HTML rapport + JSON mapping in outputDir
- Scores: >= 70 = "Uitschakelen na go-live", 50-69 = "Review vereist", < 50 = "Behouden"
- Output: `{CODE}-CA-Migratie-Analyse-{timestamp}.html` + `{CODE}-CA-Migratie-Mapping-{timestamp}.json`

### Stap 2: Carryover (Apply-CaExclusionCarryover.ps1) — PIM vereist voor live
- Leest de JSON mapping uit stap 1
- Voegt exclusions van bestaande policies met score >= 70 toe aan de DSC baseline equivalenten
- Altijd eerst dry-run, dan live na goedkeuring
- Merge is additief: bestaande exclusions worden NOOIT overschreven
- Verificatie ingebouwd: GET na PATCH, controle op "Merge OK" in output

---

## Auth — altijd delegated (verplicht)

DSC-klanten: app registration (client_credentials) werkt NIET. Altijd delegated:
- Stap 1 (Analyse): read-only scopes (Policy.Read.All, Directory.Read.All)
- Stap 2 dry-run: read-only scopes
- Stap 2 live: write scopes (Policy.ReadWrite.ConditionalAccess erbij)

Het script vraagt om device code auth — gebruiker gaat naar https://microsoft.com/devicelogin en voert de code in.
PIM voor live: Conditional Access Administrator of Global Administrator.
Waarschuw VOOR live: "Zorg dat PIM actief is voordat je verder gaat."

---

## Stap-voor-stap uitvoering

### Stap 1: Analyse draaien
1. Lees klant-config.json — bepaal welke klant en outputDir
2. Start Analyze-CaMigratie.ps1 via PowerShell terminal
3. Gebruiker voert device code in op https://microsoft.com/devicelogin
4. Wacht op "=== KLAAR ===" in output
5. Lees het HTML rapport en de JSON mapping
6. Bespreek bevindingen:
   - Hoeveel DSC baseline policies gevonden?
   - Welke bestaande policies hebben hoge overlap-score (>= 70)?
   - Welke exclusions zijn voorgesteld voor carryover?
7. Bevestig of de mapping klopt — ga naar stap 2 als OK

### Stap 2: Carryover uitvoeren
1. Altijd eerst dry-run: Apply-CaExclusionCarryover.ps1 -DryRun $true
2. Lees dry-run output: welke users/groepen worden toegevoegd per policy?
3. Bevestig: "Ziet dit er goed uit? Dan live uitvoeren."
4. PIM-waarschuwing: "Zorg dat PIM actief is."
5. Start live: -DryRun $false
6. Verificeer output: zoek naar "Merge OK" per policy
7. Check samenvatting tabel aan het einde

---

## Veelvoorkomende situaties

| Situatie | Aanpak |
|---|---|
| "CA migratie analyseren voor WSR" | Stap 1: Analyze-CaMigratie.ps1 voor WSR |
| "Overlap analyse CA HZN" | Stap 1: Analyze-CaMigratie.ps1 voor HZN |
| "Carryover exclusions toepassen" | Stap 2: dry-run eerst, dan live na goedkeuring |
| "Welke bestaande CA policies overlappen met DSC baseline?" | Stap 1 draaien, HTML rapport bekijken |
| "CA overgang plannen voor RGV" | Stap 1 draaien, bevindingen bespreken, stap 2 plannen |

---

## Bekende valkuilen

- CAL001 named location IDs zijn ALTIJD tenant-specifiek. Nooit kopiëren vanuit een andere tenant.
- Workshop policies (config.workshopPolicies) worden nooit aangeraakt.
- Score >= 70 is een voorstel, geen garantie. Gebruiker beslist altijd of carryover plaatsvindt.
- Merge is additief: als een exclusion al aanwezig is, wordt die overgeslagen (geen duplicaten).
- PIM verlopen tijdens script: auth-fout → heractiveer PIM → script opnieuw starten.
- De JSON mapping bevat alleen entries met score >= 70 EN minimaal één exclusion om over te zetten.

---

## Embedded Scripts

**Gebruik deze code blokken om de scripts naar disk te schrijven als ze ontbreken.**

### Analyze-CaMigratie.ps1
Pad: `C:\Drop\DSC\Scripts\Template\Analyze-CaMigratie.ps1`

```powershell
<#
.SYNOPSIS
    Analyseert CA policies in een tenant: classificeert DSC baseline vs bestaande policies,
    berekent overlap-scores en genereert een HTML rapport + JSON mapping voor carryover.
    Read-only -- geen PIM vereist.

.EXAMPLE
    .\Analyze-CaMigratie.ps1 -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json"
#>
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

$ErrorActionPreference = "Stop"

# ---- Config laden ---------------------------------------------------------------
$config    = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$klantCode = $config.klant.code
$klantNaam = $config.klant.naam
$tenantId  = $config.klant.tenantId
$outputDir = $config.klant.outputDir
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$logFile   = Join-Path $outputDir "Analyze-CaMigratie-$timestamp.log"

if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$Log = [System.Collections.Generic.List[string]]::new()
function Write-Log {
    param([string]$Msg, [string]$Color = "Cyan")
    $line = "[$(Get-Date -Format HH:mm:ss)] $Msg"
    $Log.Add($line)
    Write-Host $line -ForegroundColor $Color
}

Write-Log "=== Analyze-CaMigratie -- $klantNaam ($klantCode) ===" -Color Yellow
Write-Log "Tenant: $tenantId"
Write-Log "Output: $outputDir"

# ---- Modules (alleen base auth module nodig voor Invoke-MgGraphRequest) ---------
if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication")) {
    Write-Log "Microsoft.Graph.Authentication niet gevonden -- installeren..." -Color Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# ---- Auth (read-only, delegated) ------------------------------------------------
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
$scopes = @("Policy.Read.All", "Directory.Read.All")
Write-Log "Login via device code. Ga naar https://microsoft.com/devicelogin en voer de code in." -Color Yellow
Connect-MgGraph -TenantId $tenantId -Scopes $scopes -NoWelcome -UseDeviceAuthentication -ContextScope Process
$ctx = Get-MgContext
Write-Log "Verbonden: $($ctx.TenantId) / $($ctx.Account)" -Color Green

# ---- CA policies ophalen (via REST -- werkt met alle auth methodes) -------------
Write-Log "CA policies ophalen..."
$allPolicies = [System.Collections.Generic.List[object]]::new()
$nextUri = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$top=999"
do {
    $resp = Invoke-MgGraphRequest -Method GET -Uri $nextUri -OutputType Json | ConvertFrom-Json
    foreach ($p in $resp.value) { $allPolicies.Add($p) }
    $nextUri = if ($resp.'@odata.nextLink') { $resp.'@odata.nextLink' } else { $null }
} while ($nextUri)
Write-Log "Totaal gevonden: $($allPolicies.Count) policies"

$workshopPolicies = @($config.workshopPolicies | Where-Object { $_ })

# ---- Classificatie --------------------------------------------------------------
$dscBaseline = [System.Collections.Generic.List[object]]::new()
$existing    = [System.Collections.Generic.List[object]]::new()

foreach ($pol in $allPolicies) {
    $prefix = ($pol.DisplayName -split "-")[0]
    if ($pol.DisplayName -match "^CA[DLUP]\d{3}") {
        $isWorkshop = $workshopPolicies -contains $prefix
        $dscBaseline.Add([pscustomobject]@{
            Policy    = $pol
            IsWorkshop = $isWorkshop
        })
    } else {
        $existing.Add([pscustomobject]@{ Policy = $pol })
    }
}

Write-Log "Classificatie: DSC baseline=$($dscBaseline.Count)  Bestaand=$($existing.Count)"

# ---- Feature extractie ----------------------------------------------------------
function Get-PolicyFeatures {
    param($pol)
    $cond = $pol.Conditions
    $grant = $pol.GrantControls

    $incUsers = @($cond.Users.IncludeUsers | Where-Object { $_ })
    $incRoles = @($cond.Users.IncludeRoles | Where-Object { $_ })
    $incApps  = @($cond.Applications.IncludeApplications | Where-Object { $_ })
    $clientAppTypes = @($cond.ClientAppTypes | Where-Object { $_ })
    $builtIn  = @($grant.BuiltInControls | Where-Object { $_ })

    return [pscustomobject]@{
        TargetAll           = $incUsers -contains "All"
        TargetAdmins        = $incRoles.Count -gt 0
        TargetGuests        = $incUsers -contains "GuestsOrExternalUsers"
        AppAll              = $incApps -contains "All"
        AppOffice           = $incApps -contains "Office365"
        AppAzure            = $incApps -contains "MicrosoftAzureManagement"
        RequireMFA          = $builtIn -contains "mfa"
        RequireCompliant    = $builtIn -contains "compliantDevice"
        RequireHybridJoined = $builtIn -contains "domainJoinedDevice"
        Block               = ($grant.Operator -eq "block") -or ($builtIn -contains "block")
        HasLocation         = (@($cond.Locations.IncludeLocations | Where-Object { $_ }).Count -gt 0)
        HasUserRisk         = (@($cond.UserRiskLevels | Where-Object { $_ }).Count -gt 0)
        HasSignInRisk       = (@($cond.SignInRiskLevels | Where-Object { $_ }).Count -gt 0)
        LegacyAuth          = ($clientAppTypes | Where-Object { $_ -match "exchangeActiveSync|other" }).Count -gt 0
    }
}

$featureWeights = @{
    TargetAll           = 3
    TargetAdmins        = 3
    TargetGuests        = 2
    AppAll              = 2
    AppOffice           = 2
    AppAzure            = 2
    RequireMFA          = 3
    RequireCompliant    = 3
    RequireHybridJoined = 2
    Block               = 3
    HasLocation         = 3
    HasUserRisk         = 3
    HasSignInRisk       = 3
    LegacyAuth          = 3
}

# ---- Feature maps bouwen --------------------------------------------------------
Write-Log "Features berekenen voor alle policies..."

$dscFeatures = @{}
foreach ($entry in $dscBaseline) {
    $dscFeatures[$entry.Policy.Id] = Get-PolicyFeatures $entry.Policy
}

$existingFeatures = @{}
foreach ($entry in $existing) {
    $existingFeatures[$entry.Policy.Id] = Get-PolicyFeatures $entry.Policy
}

# ---- Similarity score berekening (Jaccard) --------------------------------------
function Get-SimilarityScore {
    param($featA, $featB)
    $matchWeight    = 0
    $relevantWeight = 0
    foreach ($key in $featureWeights.Keys) {
        $aTrue = $featA.$key -eq $true
        $bTrue = $featB.$key -eq $true
        if ($aTrue -or $bTrue) {
            $relevantWeight += $featureWeights[$key]
            if ($aTrue -and $bTrue) { $matchWeight += $featureWeights[$key] }
        }
    }
    if ($relevantWeight -eq 0) { return 0 }
    return [math]::Round(($matchWeight / $relevantWeight) * 100)
}

# ---- User GUIDs resolven --------------------------------------------------------
Write-Log "User display names resolven..."
$userCache = @{}
function Resolve-UserId {
    param([string]$uid)
    if ($userCache.ContainsKey($uid)) { return $userCache[$uid] }
    try {
        $u = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$uid" -OutputType Json -ErrorAction Stop | ConvertFrom-Json
        $userCache[$uid] = $u.DisplayName
        return $u.DisplayName
    } catch {
        $userCache[$uid] = $uid
        return $uid
    }
}

# ---- Bestaande policies overlapping zoeken --------------------------------------
Write-Log "Overlap analyse..."
$existingResults = [System.Collections.Generic.List[object]]::new()

foreach ($entry in $existing) {
    $pol     = $entry.Policy
    $featEx  = $existingFeatures[$pol.Id]
    $excU    = @($pol.Conditions.Users.ExcludeUsers  | Where-Object { $_ })
    $excG    = @($pol.Conditions.Users.ExcludeGroups | Where-Object { $_ })

    $candidates = [System.Collections.Generic.List[object]]::new()

    foreach ($dEntry in $dscBaseline) {
        $dPol  = $dEntry.Policy
        $featD = $dscFeatures[$dPol.Id]
        $score = Get-SimilarityScore $featEx $featD
        if ($score -ge 50) {
            $candidates.Add([pscustomobject]@{
                policyId    = $dPol.Id
                displayName = $dPol.DisplayName
                score       = $score
            })
        }
    }

    $top3 = @($candidates | Sort-Object score -Descending | Select-Object -First 3)

    $resolvedUsers  = @($excU | ForEach-Object { Resolve-UserId $_ })
    $resolvedGroups = @($excG | ForEach-Object { $_ })

    $recommendation = if ($top3.Count -gt 0 -and $top3[0].score -ge 70) {
        "Uitschakelen na DSC go-live"
    } elseif ($top3.Count -gt 0 -and $top3[0].score -ge 50) {
        "Review vereist"
    } else {
        "Behouden of handmatig beoordelen"
    }

    $existingResults.Add([pscustomobject]@{
        Policy            = $pol
        ExcludeUsers      = $excU
        ExcludeGroups     = $excG
        ResolvedUsers     = $resolvedUsers
        ResolvedGroups    = $resolvedGroups
        OverlapCandidates = $top3
        Recommendation    = $recommendation
    })
}

# ---- Carryover mapping bouwen ---------------------------------------------------
Write-Log "Carryover mapping bouwen..."
$carryoverMapping = [System.Collections.Generic.List[object]]::new()

foreach ($exResult in $existingResults) {
    if ($exResult.OverlapCandidates.Count -gt 0 -and $exResult.OverlapCandidates[0].score -ge 70) {
        $topCandidate  = $exResult.OverlapCandidates[0]
        $usersToCarry  = @($exResult.ExcludeUsers  | Where-Object { $_ })
        $groupsToCarry = @($exResult.ExcludeGroups | Where-Object { $_ })

        if ($usersToCarry.Count -gt 0 -or $groupsToCarry.Count -gt 0) {
            $resolvedCarryUsers = @($usersToCarry | ForEach-Object { Resolve-UserId $_ })
            $carryoverMapping.Add([pscustomobject]@{
                bronPolicyId             = $exResult.Policy.Id
                bronDisplayName          = $exResult.Policy.DisplayName
                doelPolicyId             = $topCandidate.policyId
                doelDisplayName          = $topCandidate.displayName
                usersToCarryover         = $usersToCarry
                groupsToCarryover        = $groupsToCarry
                resolvedUsersToCarryover = $resolvedCarryUsers
                autoApply                = $true
            })
        }
    }
}

Write-Log "Carryover entries: $($carryoverMapping.Count)"

# ---- DSC baseline samenvatting voor rapport -------------------------------------
$dscResultList = [System.Collections.Generic.List[object]]::new()
foreach ($entry in $dscBaseline) {
    $pol  = $entry.Policy
    $excU = @($pol.Conditions.Users.ExcludeUsers  | Where-Object { $_ })
    $excG = @($pol.Conditions.Users.ExcludeGroups | Where-Object { $_ })
    $dscResultList.Add([pscustomobject]@{
        Policy        = $pol
        ExcludeUsers  = $excU
        ExcludeGroups = $excG
        IsWorkshop    = $entry.IsWorkshop
    })
}

# ---- HTML rapport genereren -----------------------------------------------------
Write-Log "HTML rapport genereren..."
$reportFile = Join-Path $outputDir "$klantCode-CA-Migratie-Analyse-$timestamp.html"

$sb = [System.Text.StringBuilder]::new()
[void]$sb.Append('<!DOCTYPE html><html lang="nl"><head><meta charset="UTF-8">')
[void]$sb.Append('<title>CA Migratie Analyse - ')
[void]$sb.Append($klantNaam)
[void]$sb.Append('</title>')
[void]$sb.Append('<style>')
[void]$sb.Append('body{font-family:Consolas,monospace;background:#1e1e1e;color:#d4d4d4;margin:20px;font-size:13px;}')
[void]$sb.Append('h1{color:#4ec9b0;border-bottom:1px solid #444;padding-bottom:8px;}')
[void]$sb.Append('h2{color:#9cdcfe;margin-top:30px;}')
[void]$sb.Append('table{border-collapse:collapse;width:100%;margin-top:10px;}')
[void]$sb.Append('th{background:#2d2d2d;color:#9cdcfe;padding:8px;border:1px solid #444;text-align:left;}')
[void]$sb.Append('td{padding:7px;border:1px solid #333;vertical-align:top;}')
[void]$sb.Append('tr:hover td{background:#252525;}')
[void]$sb.Append('.row-green td{background:#1a2e1a;}.row-green:hover td{background:#1f3a1f;}')
[void]$sb.Append('.row-yellow td{background:#2e2a1a;}.row-yellow:hover td{background:#3a351f;}')
[void]$sb.Append('.row-red td{background:#2e1a1a;}.row-red:hover td{background:#3a1f1f;}')
[void]$sb.Append('.badge{display:inline-block;padding:2px 8px;border-radius:3px;font-size:11px;}')
[void]$sb.Append('.badge-enabled{background:#1a3a1a;color:#4ec9b0;}')
[void]$sb.Append('.badge-disabled{background:#3a3a1a;color:#dcdcaa;}')
[void]$sb.Append('.badge-reportonly{background:#3a1a1a;color:#f48771;}')
[void]$sb.Append('.badge-workshop{background:#1a1a3a;color:#569cd6;}')
[void]$sb.Append('.badge-score-high{background:#1a3a1a;color:#4ec9b0;}')
[void]$sb.Append('.badge-score-med{background:#3a2a1a;color:#ce9178;}')
[void]$sb.Append('.badge-score-low{background:#2d2d2d;color:#808080;}')
[void]$sb.Append('.badge-golive{background:#1a2a3a;color:#9cdcfe;}')
[void]$sb.Append('.badge-active{background:#1a3a1a;color:#4ec9b0;}')
[void]$sb.Append('.badge-noaction{background:#2d2d2d;color:#808080;}')
[void]$sb.Append('.badge-never{background:#3a1a1a;color:#f48771;}')
[void]$sb.Append('.badge-monitor{background:#3a2a1a;color:#dcdcaa;}')
[void]$sb.Append('.box{display:inline-block;background:#2d2d2d;border:1px solid #444;padding:15px 25px;margin:5px;text-align:center;border-radius:4px;}')
[void]$sb.Append('.box-num{font-size:28px;color:#4ec9b0;}.box-lbl{font-size:11px;color:#808080;}')
[void]$sb.Append('.phase-block{background:#252525;border-left:3px solid #569cd6;padding:10px 15px;margin:8px 0;border-radius:0 4px 4px 0;}')
[void]$sb.Append('.phase-title{color:#569cd6;font-weight:bold;}')
[void]$sb.Append('</style></head><body>')

# Header
[void]$sb.Append('<h1>CA Migratie Analyse -- ')
[void]$sb.Append($klantNaam)
[void]$sb.Append('</h1>')
[void]$sb.Append('<p>Tenant: <code>')
[void]$sb.Append($tenantId)
[void]$sb.Append('</code> &nbsp;|&nbsp; Datum: ')
[void]$sb.Append((Get-Date -Format "yyyy-MM-dd HH:mm"))
[void]$sb.Append('</p>')

# Sectie 1: Samenvatting
$overlapCount = ($existingResults | Where-Object { $_.OverlapCandidates.Count -gt 0 }).Count
[void]$sb.Append('<h2>1. Samenvatting</h2>')
[void]$sb.Append('<div class="box"><div class="box-num">')
[void]$sb.Append($dscBaseline.Count)
[void]$sb.Append('</div><div class="box-lbl">DSC Baseline policies</div></div>')
[void]$sb.Append('<div class="box"><div class="box-num">')
[void]$sb.Append($existing.Count)
[void]$sb.Append('</div><div class="box-lbl">Bestaande policies</div></div>')
[void]$sb.Append('<div class="box"><div class="box-num">')
[void]$sb.Append($overlapCount)
[void]$sb.Append('</div><div class="box-lbl">Overlap gevonden</div></div>')

# Sectie 2: DSC Baseline tabel
[void]$sb.Append('<h2>2. DSC Baseline Policies</h2>')
[void]$sb.Append('<table><tr><th>Naam</th><th>Status</th><th>Actie bij Go-Live</th><th>Excl. Users</th><th>Excl. Groepen</th></tr>')

foreach ($r in $dscResultList | Sort-Object { $_.Policy.DisplayName }) {
    $state = $r.Policy.State
    $rowClass = switch ($state) {
        "enabled"                          { "row-green" }
        "disabled"                         { "row-yellow" }
        "enabledForReportingButNotEnforced" { "row-red" }
        default                            { "" }
    }
    $badgeClass = switch ($state) {
        "enabled"                          { "badge-enabled" }
        "disabled"                         { "badge-disabled" }
        "enabledForReportingButNotEnforced" { "badge-reportonly" }
        default                            { "badge-disabled" }
    }
    $stateLabel = switch ($state) {
        "enabled"                          { "Enabled" }
        "disabled"                         { "Disabled" }
        "enabledForReportingButNotEnforced" { "Report-only" }
        default                            { $state }
    }
    $actionLabel = if ($r.IsWorkshop) {
        '<span class="badge badge-never">Nooit inschakelen (Workshop)</span>'
    } elseif ($state -eq "enabled") {
        '<span class="badge badge-active">Al actief -- behouden</span>'
    } elseif ($state -eq "enabledForReportingButNotEnforced") {
        '<span class="badge badge-monitor">Report-only -- live zetten bij go-live</span>'
    } else {
        '<span class="badge badge-golive">Inschakelen bij go-live</span>'
    }
    $excUList = if ($r.ExcludeUsers.Count -gt 0) {
        ($r.ExcludeUsers | ForEach-Object { Resolve-UserId $_ }) -join "<br>"
    } else { "-" }
    $excGList = if ($r.ExcludeGroups.Count -gt 0) { $r.ExcludeGroups -join "<br>" } else { "-" }

    [void]$sb.Append('<tr class="')
    [void]$sb.Append($rowClass)
    [void]$sb.Append('"><td>')
    [void]$sb.Append($r.Policy.DisplayName)
    [void]$sb.Append('</td><td><span class="badge ')
    [void]$sb.Append($badgeClass)
    [void]$sb.Append('">')
    [void]$sb.Append($stateLabel)
    [void]$sb.Append('</span></td><td>')
    [void]$sb.Append($actionLabel)
    [void]$sb.Append('</td><td>')
    [void]$sb.Append($excUList)
    [void]$sb.Append('</td><td>')
    [void]$sb.Append($excGList)
    [void]$sb.Append('</td></tr>')
}
[void]$sb.Append('</table>')

# Sectie 3: Bestaande policies
[void]$sb.Append('<h2>3. Bestaande Policies (tenant-specifiek)</h2>')
[void]$sb.Append('<table><tr><th>Naam</th><th>Status</th><th>Excl. Users</th><th>Excl. Groepen</th><th>Overlap-kandidaat</th><th>Score</th><th>Aanbeveling</th></tr>')

foreach ($r in $existingResults | Sort-Object { $_.Policy.DisplayName }) {
    $state = $r.Policy.State
    $rowClass = switch ($state) {
        "enabled"                          { "row-green" }
        "disabled"                         { "row-yellow" }
        "enabledForReportingButNotEnforced" { "row-red" }
        default                            { "" }
    }
    $badgeClass = switch ($state) {
        "enabled"                          { "badge-enabled" }
        "disabled"                         { "badge-disabled" }
        "enabledForReportingButNotEnforced" { "badge-reportonly" }
        default                            { "badge-disabled" }
    }
    $stateLabel = switch ($state) {
        "enabled"                          { "Enabled" }
        "disabled"                         { "Disabled" }
        "enabledForReportingButNotEnforced" { "Report-only" }
        default                            { $state }
    }

    $topCand    = if ($r.OverlapCandidates.Count -gt 0) { $r.OverlapCandidates[0] } else { $null }
    $candName   = if ($topCand) { $topCand.displayName } else { "-" }
    $score      = if ($topCand) { $topCand.score } else { 0 }
    $scoreBadge = if ($score -ge 70) { "badge-score-high" } elseif ($score -ge 50) { "badge-score-med" } else { "badge-score-low" }
    $scoreLabel = if ($topCand) { "$score%" } else { "-" }

    $excUList = if ($r.ResolvedUsers.Count -gt 0) { $r.ResolvedUsers -join "<br>" } else { "-" }
    $excGList = if ($r.ResolvedGroups.Count -gt 0) { $r.ResolvedGroups -join "<br>" } else { "-" }

    [void]$sb.Append('<tr class="')
    [void]$sb.Append($rowClass)
    [void]$sb.Append('"><td>')
    [void]$sb.Append($r.Policy.DisplayName)
    [void]$sb.Append('</td><td><span class="badge ')
    [void]$sb.Append($badgeClass)
    [void]$sb.Append('">')
    [void]$sb.Append($stateLabel)
    [void]$sb.Append('</span></td><td>')
    [void]$sb.Append($excUList)
    [void]$sb.Append('</td><td>')
    [void]$sb.Append($excGList)
    [void]$sb.Append('</td><td>')
    [void]$sb.Append($candName)
    [void]$sb.Append('</td><td><span class="badge ')
    [void]$sb.Append($scoreBadge)
    [void]$sb.Append('">')
    [void]$sb.Append($scoreLabel)
    [void]$sb.Append('</span></td><td>')
    [void]$sb.Append($r.Recommendation)
    [void]$sb.Append('</td></tr>')
}
[void]$sb.Append('</table>')

# Sectie 4: Carryover plan
[void]$sb.Append('<h2>4. Carryover Plan</h2>')
$carryWithData = @($carryoverMapping | Where-Object { $_.usersToCarryover.Count -gt 0 -or $_.groupsToCarryover.Count -gt 0 })

if ($carryWithData.Count -eq 0) {
    [void]$sb.Append('<p>Geen exclusions gevonden die overgezet moeten worden.</p>')
} else {
    [void]$sb.Append('<table><tr><th>Van (bestaand)</th><th>Naar (DSC baseline)</th><th>Mee te nemen users</th><th>Mee te nemen groepen</th></tr>')
    foreach ($c in $carryWithData) {
        $usersList  = if ($c.resolvedUsersToCarryover.Count -gt 0) { $c.resolvedUsersToCarryover -join "<br>" } else { "-" }
        $groupsList = if ($c.groupsToCarryover.Count -gt 0) { $c.groupsToCarryover -join "<br>" } else { "-" }

        [void]$sb.Append('<tr><td>')
        [void]$sb.Append($c.bronDisplayName)
        [void]$sb.Append('</td><td>')
        [void]$sb.Append($c.doelDisplayName)
        [void]$sb.Append('</td><td>')
        [void]$sb.Append($usersList)
        [void]$sb.Append('</td><td>')
        [void]$sb.Append($groupsList)
        [void]$sb.Append('</td></tr>')
    }
    [void]$sb.Append('</table>')
}

# Sectie 5: Migratie aanpak (inklapbaar)
[void]$sb.Append('<details style="margin-top:20px;"><summary style="cursor:pointer;color:#9cdcfe;font-size:15px;font-weight:bold;padding:6px 0;list-style:none;">')
[void]$sb.Append('&#9654; 5. Migratie Aanpak (klik om te tonen/verbergen)')
[void]$sb.Append('</summary>')
[void]$sb.Append('<div style="margin-top:10px;">')
[void]$sb.Append('<div class="phase-block"><span class="phase-title">Fase 1: BTG Exclusions</span><br>Standaard BTG user exclusions toevoegen aan alle DSC baseline policies.<br>Script: <code>Phase3-BTGExclusions.ps1</code></div>')
[void]$sb.Append('<div class="phase-block"><span class="phase-title">Fase 2: Carryover Exclusions</span><br>Exclusions van bestaande policies met hoge overlap-score overnemen naar DSC baseline.<br>Script: <code>Apply-CaExclusionCarryover.ps1</code> -- eerst dry-run, dan live. PIM vereist.</div>')
[void]$sb.Append('<div class="phase-block"><span class="phase-title">Fase 3: DSC Baseline naar Report-only</span><br>Alle DSC baseline policies activeren in report-only modus (monitorfase).<br>Script: <code>Phase4-ReportOnly.ps1</code></div>')
[void]$sb.Append('<div class="phase-block"><span class="phase-title">Fase 4: Go-live</span><br>DSC baseline policies inschakelen op enabled. Bestaande overlappende policies uitschakelen na validatie. Datum afstemmen met contactpersoon: ')
[void]$sb.Append($config.golive.contactPersoon)
[void]$sb.Append('.</div></div></details>')

# Footer
$jsonFileName = "$klantCode-CA-Migratie-Mapping-$timestamp.json"
$jsonPath     = Join-Path $outputDir $jsonFileName
[void]$sb.Append('<hr style="border-color:#444;margin-top:30px;">')
[void]$sb.Append('<details><summary style="cursor:pointer;color:#808080;font-size:11px;list-style:none;">&#9654; Technische details</summary>')
[void]$sb.Append('<p style="color:#808080;font-size:11px;margin-top:6px;">Gegenereerd door Analyze-CaMigratie.ps1 &nbsp;|&nbsp; ')
[void]$sb.Append((Get-Date -Format "yyyy-MM-dd HH:mm"))
[void]$sb.Append(' &nbsp;|&nbsp; JSON mapping: <code>')
[void]$sb.Append($jsonPath)
[void]$sb.Append('</code></p></details></body></html>')

$sb.ToString() | Out-File $reportFile -Encoding UTF8
Write-Log "HTML rapport opgeslagen: $reportFile" -Color Green

# ---- JSON mapping opslaan -------------------------------------------------------
Write-Log "JSON mapping opslaan..."

$dscJsonList = @($dscResultList | ForEach-Object {
    $pol  = $_.Policy
    $excU = @($pol.Conditions.Users.ExcludeUsers  | Where-Object { $_ })
    $excG = @($pol.Conditions.Users.ExcludeGroups | Where-Object { $_ })
    [ordered]@{
        policyId      = $pol.Id
        displayName   = $pol.DisplayName
        state         = $pol.State
        excludeUsers  = $excU
        excludeGroups = $excG
        isWorkshop    = $_.IsWorkshop
    }
})

$existJsonList = @($existingResults | ForEach-Object {
    $pol = $_.Policy
    [ordered]@{
        policyId      = $pol.Id
        displayName   = $pol.DisplayName
        state         = $pol.State
        excludeUsers  = $_.ExcludeUsers
        excludeGroups = $_.ExcludeGroups
        overlapCandidates = @($_.OverlapCandidates | ForEach-Object {
            [ordered]@{ policyId=$_.policyId; displayName=$_.displayName; score=$_.score }
        })
        recommendation = $_.Recommendation
    }
})

$carryJsonList = @($carryoverMapping | ForEach-Object {
    [ordered]@{
        bronPolicyId    = $_.bronPolicyId
        bronDisplayName = $_.bronDisplayName
        doelPolicyId    = $_.doelPolicyId
        doelDisplayName = $_.doelDisplayName
        usersToCarryover  = $_.usersToCarryover
        groupsToCarryover = $_.groupsToCarryover
        autoApply         = $_.autoApply
    }
})

$jsonOutput = [ordered]@{
    klant            = $klantCode
    tenantId         = $tenantId
    analyseDatum     = (Get-Date -Format "yyyy-MM-dd")
    dscBaseline      = $dscJsonList
    existing         = $existJsonList
    carryoverMapping = $carryJsonList
}

$jsonOutput | ConvertTo-Json -Depth 15 | Out-File $jsonPath -Encoding UTF8
Write-Log "JSON mapping opgeslagen: $jsonPath" -Color Green

# ---- Log opslaan ----------------------------------------------------------------
$Log | Out-File $logFile -Encoding UTF8
Disconnect-MgGraph | Out-Null

Write-Log "" -Color White
Write-Log "=== KLAAR ===" -Color Yellow
Write-Log "HTML rapport : $reportFile" -Color Green
Write-Log "JSON mapping : $jsonPath"   -Color Green
Write-Log "Log          : $logFile"    -Color Green
Write-Log ""
Write-Log "Volgende stap: Apply-CaExclusionCarryover.ps1 -MappingPath `"$jsonPath`" -DryRun `$true"
```

---

### Apply-CaExclusionCarryover.ps1
Pad: `C:\Drop\DSC\Scripts\Template\Apply-CaExclusionCarryover.ps1`

```powershell
<#
.SYNOPSIS
    Carryover exclusions toepassen van bestaande tenant policies naar DSC baseline policies.
    Leest mapping JSON gegenereerd door Analyze-CaMigratie.ps1.
    PIM vereist voor live uitvoering (Conditional Access Administrator of Global Administrator).

.EXAMPLE
    # Dry-run (default) -- alleen weergeven wat er zou gebeuren
    .\Apply-CaExclusionCarryover.ps1 -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json" -MappingPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\WSR-CA-Migratie-Mapping-20260323-1400.json"

    # Live uitvoeren
    .\Apply-CaExclusionCarryover.ps1 -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json" -MappingPath "....\WSR-CA-Migratie-Mapping-20260323-1400.json" -DryRun $false
#>
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [Parameter(Mandatory)][string]$MappingPath,
    [bool]$DryRun = $true
)

$ErrorActionPreference = "Stop"

# ---- Config + mapping laden -----------------------------------------------------
$config    = Get-Content $ConfigPath  -Raw | ConvertFrom-Json
$mapping   = Get-Content $MappingPath -Raw | ConvertFrom-Json

$klantCode = $config.klant.code
$klantNaam = $config.klant.naam
$tenantId  = $config.klant.tenantId
$outputDir = $config.klant.outputDir
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$modeLabel = if ($DryRun) { "DRY-RUN" } else { "LIVE" }
$logFile   = Join-Path $outputDir "Apply-CaExclusionCarryover-$modeLabel-$timestamp.log"

if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$Log = [System.Collections.Generic.List[string]]::new()
function Write-Log {
    param([string]$Msg, [string]$Color = "Cyan")
    $line = "[$(Get-Date -Format HH:mm:ss)] $Msg"
    $Log.Add($line)
    Write-Host $line -ForegroundColor $Color
}

Write-Log "=== Apply-CaExclusionCarryover ($modeLabel) ===" -Color Yellow
Write-Log "Klant      : $klantNaam ($klantCode)"
Write-Log "Tenant     : $tenantId"
Write-Log "Mapping    : $MappingPath"

# ---- Validatie ------------------------------------------------------------------
$carryoverItems = @($mapping.carryoverMapping | Where-Object { $_ })

if ($carryoverItems.Count -eq 0) {
    Write-Log "carryoverMapping is leeg in de mapping JSON. Niets te doen." -Color Yellow
    Write-Log "Voer eerst Analyze-CaMigratie.ps1 uit en controleer of er overlap gevonden is."
    exit 0
}

Write-Log "Carryover entries gevonden: $($carryoverItems.Count)"

if (-not $DryRun -and $config.auth.pimVereist) {
    Write-Log ""
    Write-Log "LET OP: PIM is vereist voor deze klant." -Color Yellow
    Write-Log "Zorg dat je actief bent als Conditional Access Administrator of Global Administrator." -Color Yellow
    Write-Log ""
}

# ---- Modules --------------------------------------------------------------------
foreach ($mod in @("Microsoft.Graph.Identity.SignIns", "Microsoft.Graph.Users")) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Log "Module $mod niet gevonden -- installeren..." -Color Yellow
        Install-Module $mod -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $mod -ErrorAction Stop
}

# ---- Auth -----------------------------------------------------------------------
$scopes = if ($DryRun) {
    @("Policy.Read.All", "Directory.Read.All")
} else {
    @("Policy.Read.All", "Policy.ReadWrite.ConditionalAccess", "Directory.Read.All")
}

Write-Log "Login via device code. Ga naar https://microsoft.com/devicelogin en voer de code in." -Color Yellow
Connect-MgGraph -TenantId $tenantId -Scopes $scopes -NoWelcome -UseDeviceAuthentication
$ctx = Get-MgContext
Write-Log "Verbonden: $($ctx.TenantId) / $($ctx.Account)" -Color Green

# ---- Per carryover entry verwerken ----------------------------------------------
$results = [System.Collections.Generic.List[object]]::new()

foreach ($entry in $carryoverItems) {
    Write-Log ""
    Write-Log "--------------------------------------------------------------" -Color White
    Write-Log "Van  : $($entry.bronDisplayName)" -Color White
    Write-Log "Naar : $($entry.doelDisplayName)" -Color White

    $usersToAdd  = @($entry.usersToCarryover  | Where-Object { $_ })
    $groupsToAdd = @($entry.groupsToCarryover | Where-Object { $_ })

    Write-Log "  Users  te carryoven : $($usersToAdd.Count)"
    Write-Log "  Groepen te carryoven: $($groupsToAdd.Count)"

    try {
        # Huidige DSC baseline policy ophalen
        $dscPol    = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $entry.doelPolicyId -ErrorAction Stop
        $curUsers  = @($dscPol.Conditions.Users.ExcludeUsers  | Where-Object { $_ })
        $curGroups = @($dscPol.Conditions.Users.ExcludeGroups | Where-Object { $_ })

        Write-Log "  Huidige excl. users  : $($curUsers.Count)"
        Write-Log "  Huidige excl. groepen: $($curGroups.Count)"

        # Merge -- uniek
        $newUsers  = @(($curUsers  + $usersToAdd)  | Select-Object -Unique | Where-Object { $_ })
        $newGroups = @(($curGroups + $groupsToAdd) | Select-Object -Unique | Where-Object { $_ })

        $addedUsers  = @($usersToAdd  | Where-Object { $curUsers  -notcontains $_ })
        $addedGroups = @($groupsToAdd | Where-Object { $curGroups -notcontains $_ })

        Write-Log "  Na merge -- users    : $($newUsers.Count)  (+$($addedUsers.Count) nieuw)"
        Write-Log "  Na merge -- groepen  : $($newGroups.Count)  (+$($addedGroups.Count) nieuw)"

        if ($addedUsers.Count -eq 0 -and $addedGroups.Count -eq 0) {
            Write-Log "  Geen nieuwe exclusions -- al aanwezig. Overgeslagen." -Color Green
            $results.Add([pscustomobject]@{
                Doel   = $entry.doelDisplayName
                Van    = $entry.bronDisplayName
                Status = "Al aanwezig"
                Actie  = "Overgeslagen"
            })
            continue
        }

        if ($DryRun) {
            Write-Log "  DRY-RUN: zou $($addedUsers.Count) users en $($addedGroups.Count) groepen toevoegen" -Color Yellow
            foreach ($u in $addedUsers)  { Write-Log "    + user : $u" }
            foreach ($g in $addedGroups) { Write-Log "    + groep: $g" }
            $results.Add([pscustomobject]@{
                Doel   = $entry.doelDisplayName
                Van    = $entry.bronDisplayName
                Status = "Dry-run"
                Actie  = "Zou $($addedUsers.Count) users + $($addedGroups.Count) groepen toevoegen"
            })
        } else {
            $body = @{
                conditions = @{
                    users = @{
                        excludeUsers  = [array]$newUsers
                        excludeGroups = [array]$newGroups
                    }
                }
            }

            Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $entry.doelPolicyId -BodyParameter $body -ErrorAction Stop

            # Verificatie
            $verified  = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $entry.doelPolicyId -ErrorAction Stop
            $verUsers  = @($verified.Conditions.Users.ExcludeUsers  | Where-Object { $_ })
            $verGroups = @($verified.Conditions.Users.ExcludeGroups | Where-Object { $_ })
            $userOk    = $addedUsers  | Where-Object { $verUsers  -notcontains $_ }
            $groupOk   = $addedGroups | Where-Object { $verGroups -notcontains $_ }

            if ($userOk.Count -eq 0 -and $groupOk.Count -eq 0) {
                Write-Log "  Merge OK -- excl. users na update: $($verUsers.Count)  groepen: $($verGroups.Count)" -Color Green
                $results.Add([pscustomobject]@{
                    Doel   = $entry.doelDisplayName
                    Van    = $entry.bronDisplayName
                    Status = "OK"
                    Actie  = "Merge OK: +$($addedUsers.Count) users, +$($addedGroups.Count) groepen"
                })
            } else {
                Write-Log "  WAARSCHUWING: verificatie mismatch -- niet alle items zijn zichtbaar na update" -Color Red
                $results.Add([pscustomobject]@{
                    Doel   = $entry.doelDisplayName
                    Van    = $entry.bronDisplayName
                    Status = "WAARSCHUWING"
                    Actie  = "Verificatie mismatch -- controleer handmatig"
                })
            }
        }

    } catch {
        Write-Log "  FOUT bij $($entry.doelDisplayName): $($_.Exception.Message)" -Color Red
        $results.Add([pscustomobject]@{
            Doel   = $entry.doelDisplayName
            Van    = $entry.bronDisplayName
            Status = "FOUT"
            Actie  = $_.Exception.Message
        })
    }
}

# ---- Samenvatting ---------------------------------------------------------------
Write-Log ""
Write-Log "=== SAMENVATTING ($modeLabel) ===" -Color White
$results | Format-Table -AutoSize

# ---- Config fase updaten (alleen bij live) ----------------------------------------
if (-not $DryRun) {
    $config.golive.fase = "carryover-done"
    $config | ConvertTo-Json -Depth 15 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Log "Config bijgewerkt: fase = carryover-done" -Color Green
    Write-Log "Volgende stap:"
    Write-Log "  .\Phase4-ReportOnly.ps1 -ConfigPath `"$ConfigPath`" -DryRun `$true"
}

# ---- Log opslaan ----------------------------------------------------------------
$Log | Out-File $logFile -Encoding UTF8
Disconnect-MgGraph | Out-Null

Write-Log "Klaar. Log: $logFile"
```

---

### Run-CaMigratie.ps1
Pad: `C:\Drop\DSC\Scripts\Run-CaMigratie.ps1`

```powershell
<#
.SYNOPSIS
    Interactieve launcher voor de DSC CA migratie workflow.
    Stap 1: Analyse (Analyze-CaMigratie.ps1) -- geen PIM nodig.
    Stap 2: Carryover dry-run of live (Apply-CaExclusionCarryover.ps1) -- PIM voor live.
#>

$ErrorActionPreference = "Stop"

$analyzeScript   = "C:\Drop\DSC\Scripts\Template\Analyze-CaMigratie.ps1"
$carryoverScript = "C:\Drop\DSC\Scripts\Template\Apply-CaExclusionCarryover.ps1"
$klantenRoot     = "C:\Drop\DSC\Klanten"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DSC CA Migratie Workflow -- Launcher"     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ---- Controleer of scripts bestaan ---------------------------------------------
foreach ($s in @($analyzeScript, $carryoverScript)) {
    if (-not (Test-Path $s)) {
        Write-Host "Script niet gevonden: $s" -ForegroundColor Red
        exit 1
    }
}

# ---- Klanten ophalen -----------------------------------------------------------
$configs = Get-ChildItem -Path $klantenRoot -Recurse -Filter "klant-config.json" -ErrorAction SilentlyContinue

if ($configs.Count -eq 0) {
    Write-Host "Geen klant-config.json gevonden in $klantenRoot" -ForegroundColor Red
    exit 1
}

$klantenLijst = @()
foreach ($c in $configs) {
    try {
        $cfg = Get-Content $c.FullName -Raw | ConvertFrom-Json
        $klantenLijst += [pscustomobject]@{
            Naam       = $cfg.klant.naam
            Code       = $cfg.klant.code
            Fase       = $cfg.golive.fase
            OutputDir  = $cfg.klant.outputDir
            ConfigPath = $c.FullName
        }
    } catch {
        Write-Host "Kon $($c.FullName) niet laden: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($klantenLijst.Count -eq 0) {
    Write-Host "Geen geldige klantconfigs gevonden." -ForegroundColor Red
    exit 1
}

# ---- Klant kiezen --------------------------------------------------------------
Write-Host "Beschikbare klanten:" -ForegroundColor White
for ($i = 0; $i -lt $klantenLijst.Count; $i++) {
    $k = $klantenLijst[$i]
    Write-Host ("  [{0}] {1,-35} ({2})  --  fase: {3}" -f ($i + 1), $k.Naam, $k.Code, $k.Fase)
}
Write-Host ""

do {
    $keuze = Read-Host "Kies een klant (1-$($klantenLijst.Count))"
} while (-not ($keuze -match "^\d+$") -or [int]$keuze -lt 1 -or [int]$keuze -gt $klantenLijst.Count)

$gekozen = $klantenLijst[[int]$keuze - 1]
Write-Host ""
Write-Host "Klant: $($gekozen.Naam) ($($gekozen.Code))" -ForegroundColor Green
Write-Host "Fase : $($gekozen.Fase)"
Write-Host ""

# ---- Actie submenu -------------------------------------------------------------
Write-Host "Beschikbare acties:" -ForegroundColor White
Write-Host "  [1] Analyse draaien          (Analyze-CaMigratie.ps1)         -- geen PIM nodig"
Write-Host "  [2] Carryover dry-run        (Apply-CaExclusionCarryover.ps1) -- geen PIM nodig"
Write-Host "  [3] Carryover live uitvoeren (Apply-CaExclusionCarryover.ps1) -- PIM VEREIST"
Write-Host ""

do {
    $actieKeuze = Read-Host "Kies actie (1/2/3)"
} while ($actieKeuze -ne "1" -and $actieKeuze -ne "2" -and $actieKeuze -ne "3")

# ---- Meest recente mapping JSON zoeken -----------------------------------------
function Find-LatestMappingJson {
    param([string]$Dir, [string]$Code)
    $pattern = "$Code-CA-Migratie-Mapping-*.json"
    $files = Get-ChildItem -Path $Dir -Filter $pattern -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending
    if ($files.Count -gt 0) { return $files[0].FullName }
    return $null
}

# ---- Actie uitvoeren -----------------------------------------------------------
switch ($actieKeuze) {
    "1" {
        Write-Host ""
        Write-Host "Starten: Analyse -- $($gekozen.Naam)" -ForegroundColor Cyan
        Write-Host "Output komt in: $($gekozen.OutputDir)"
        Write-Host ""
        & $analyzeScript -ConfigPath $gekozen.ConfigPath
    }

    "2" {
        Write-Host ""
        $mappingPath = Find-LatestMappingJson -Dir $gekozen.OutputDir -Code $gekozen.Code

        if (-not $mappingPath) {
            Write-Host "Geen mapping JSON gevonden in $($gekozen.OutputDir)" -ForegroundColor Red
            Write-Host "Voer eerst optie [1] Analyse uit om de mapping te genereren." -ForegroundColor Yellow
            exit 1
        }

        Write-Host "Mapping JSON gevonden: $mappingPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "Starten: Carryover DRY-RUN -- $($gekozen.Naam)" -ForegroundColor Cyan
        Write-Host ""

        & $carryoverScript -ConfigPath $gekozen.ConfigPath -MappingPath $mappingPath -DryRun $true
    }

    "3" {
        Write-Host ""
        $mappingPath = Find-LatestMappingJson -Dir $gekozen.OutputDir -Code $gekozen.Code

        if (-not $mappingPath) {
            Write-Host "Geen mapping JSON gevonden in $($gekozen.OutputDir)" -ForegroundColor Red
            Write-Host "Voer eerst optie [1] Analyse uit om de mapping te genereren." -ForegroundColor Yellow
            exit 1
        }

        Write-Host "Mapping JSON gevonden: $mappingPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "LET OP: Live modus. Wijzigingen worden ECHT doorgevoerd." -ForegroundColor Yellow
        Write-Host "Zorg dat PIM actief is (Conditional Access Administrator of Global Administrator)." -ForegroundColor Yellow
        Write-Host ""

        $bevestig = Read-Host "Doorgaan met LIVE carryover? (ja/nee)"
        if ($bevestig -ne "ja") {
            Write-Host "Afgebroken." -ForegroundColor Red
            exit 0
        }

        Write-Host ""
        Write-Host "Starten: Carryover LIVE -- $($gekozen.Naam)" -ForegroundColor Cyan
        Write-Host ""

        & $carryoverScript -ConfigPath $gekozen.ConfigPath -MappingPath $mappingPath -DryRun $false
    }
}
```

---

### klant-config.template.json
Pad: `C:\Drop\DSC\Klanten\{CODE} - {Naam}\klant-config.json`

```json
{
  "klant": {
    "naam": "",
    "code": "",
    "tenantId": "",
    "outputDir": "C:\\Drop\\DSC\\Klanten\\"
  },

  "auth": {
    "pimVereist": true
  },

  "btgAccounts": {
    "upns": []
  },

  "golive": {
    "datum": "",
    "contactPersoon": "",
    "fase": "audit"
  },

  "workshopPolicies": ["CAD006", "CAD013", "CAD014", "CAD017", "CAL003", "CAU003", "CAU009", "CAU010"],
  "alreadyEnabled": ["CAD018"],

  "discovered": {
    "btgObjectIds": [],
    "dscPolicies": [],
    "preExistingPolicies": [],
    "namedLocations": [],
    "exclusionTargets": {
      "cad001Id": null,
      "cad004Id": null,
      "cad005Id": null
    },
    "cal001Id": null,
    "groups": {}
  }
}
```
