---
name: dsc-ca-baseline
description: >
  DSC Conditional Access (CA) baseline go-live workflow -- uitsluitend voor DSC-klanten: Woonstad Rotterdam, Gemeente Huizen, Regio Gooi en Vechtstreek.
  Intune baseline is CarePilot-specifiek en valt NOOIT onder deze skill.
  Trigger bij: "CA baseline live zetten bij [DSC-klant]", "Conditional Access uitrollen bij WSR/HZN/RGV",
  "CA Phase 1/2/3/4 uitvoeren", "BTG exclusions toevoegen aan DSC-klant", "CA policies naar report-only",
  "CA go-live plan of PPTX genereren voor DSC-klant", of wanneer "CA", "Conditional Access", "report-only"
  of "BTG exclusion" samen met een DSC-klant voorkomen.
  Niet triggeren bij: CarePilot, Vertimart, Intune baseline, MDM baseline, compliance policy, device policy,
  of enige combinatie met CarePilot-klanten -- ook niet als daar CA-termen in voorkomen.
  De skill voert het volledige CA-proces autonoom uit: config laden, scripts draaien via Desktop Commander,
  output reviewen, en de PowerPoint genereren - alles op basis van klant-config.json.
---

# DSC CA Baseline -- Go-Live Skill

Scope: uitsluitend DSC Conditional Access. Intune baseline = CarePilot, valt hier NIET onder.

## Bekende DSC-klanten

| Klant | Code | Tenant ID | Config |
|---|---|---|---|
| Woonstad Rotterdam | WSR | f4cd4ee9-43a6-4256-a5e0-016c044746c8 | C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json |
| Gemeente Huizen | HZN | bc49eac0-d8da-4ed9-b328-91c793d8b02e | C:\Drop\DSC\Klanten\HZN - Gemeente Huizen\klant-config.json |
| Regio Gooi en Vechtstreek | RGV | 3d4f9081-0beb-452f-a8cf-7203e3681edc | C:\Drop\DSC\Klanten\RGV - Regio Gooi en Vechtstreek\klant-config.json |

Alle drie hebben PIM. Scripts staan in C:\Drop\DSC\Scripts\Template\
Volledig runbook: Obsidian > DSC/Runbooks/DSC-CA-Baseline-Golive-Runbook.md

---

## Eerste stap: context bepalen

Lees altijd eerst de klant-config.json. Let op golive.fase:
- "nieuw"                 -- begin bij Phase 1
- "audit-complete"        -- Phase 1 klaar, ga naar Phase 2
- "report-only-pending"   -- Phase 3/4 aan de beurt
- "report-only-done"      -- alles gedaan, alleen PPTX nog

---

## Auth -- delegated browser-login (verplicht voor alle fases)

DSC-klanten: app registration (client_credentials) is NOOIT mogelijk. Altijd delegated auth:
- Phase 1 en 2: read-only scopes (Policy.Read.All, Directory.Read.All)
- Phase 3 en 4: write scopes (Policy.ReadWrite.ConditionalAccess erbij)

Het script roept Connect-MgGraph aan -- Robin klikt Accept in de browser-popup.
Waarschuw VOOR Phase 3 of 4: "Er verschijnt een browser-popup -- klik Accept."

PIM: scripts vereisen Conditional Access Administrator of Global Administrator.
Wacht op PIM-bevestiging VOOR je Phase 3 of 4 start.

---

## Scripts uitvoeren via Desktop Commander

Gebruik mcp__Desktop_Commander__start_process, shell: cmd

Voorbeeld:
  powershell.exe -NoExit -File "C:\Drop\DSC\Scripts\Template\Phase1-Audit.ps1" -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json"

Altijd -NoExit. Output lezen via read_process_output.
Bij Phase 3 en 4: altijd eerst -DryRun $true, dan pas -DryRun $false na goedkeuring Robin + browser Accept.

---

## Fases

### Phase 0 -- Nieuwe klant (alleen als config ontbreekt)
.\New-KlantConfig.ps1 -KlantNaam "..." -KlantCode "XXX" -TenantId "..." -BTGUpns @("upn1","upn2") -ContactPersoon "..."

### Phase 1 -- Audit (read-only)
Script: Phase1-Audit.ps1
Daarna reviewen: DSC policies herkend? CAD018 al enabled (normaal)? CAD001/004/005 in exclusionTargets?

### Phase 2 -- Groepen & Named Locations (read-only)
Script: Phase2-CheckGroups.ps1
Let op: SG-UG-PIM-Workplace moet leden hebben. CAL001 named locations zijn staging-specifiek -- blocker melden.

### Phase 3 -- BTG exclusions (schrijft -- PIM vereist)
Vereiste: discovered.btgObjectIds gevuld in config (door Phase1-Audit.ps1).
Zo niet: vraag Robin om de BTG account UPNs en zoek object IDs op via Get-MgUser.
Targeted: ALLE DSC baseline policies (^CA[DLUP]\d{3}) minus workshopPolicies.
Bestaande exclusions worden BEWAARD (merge, niet replace).
Volgorde: dry-run tonen -> goedkeuring Robin -> live (browser-popup)
Verificatie ingebouwd: controleer "PATCH OK -- exclusions na update" in output.

### Phase 4 -- Report-only (schrijft -- PIM vereist)
Script: Phase4-ReportOnly.ps1
Volgorde: dry-run -> goedkeuring -> live
Workshop-policies en CAD018 worden automatisch overgeslagen.

### Phase 5 -- PPTX genereren
Script: Build-GolivePresentation.ps1
Output: <outputDir>\<CODE>-CA-Golive-Plan.pptx -- opent automatisch in PowerPoint.

Gebruik altijd de officiële DSC PowerPoint template als basis:
  Template: C:\Users\Home Mini\Documents\Pegasus\Templates\DSC\PowerPoint\Workshop_Technisch.pptx
  DSC branding: font Poppins, kleur #06BBC1
  Via pptx skill: unpack template -> slides aanpassen -> repack

---

## Veelvoorkomende situaties

"CA baseline live zetten bij HZN"
-> config laden -> fase bepalen -> fases doorlopen, PIM-waarschuwing voor Phase 3/4

"BTG exclusions toevoegen aan RGV"
-> btgAccounts.upns check -> PIM-waarschuwing -> dry-run -> live

"Maak CA go-live plan voor WSR"
-> check of Phase1 gedaan is -> zo niet, eerst auditen -> PPTX genereren

"Nieuwe DSC-klant: [naam], tenant [ID]"
-> New-KlantConfig.ps1 aanroepen

---

## Bekende valkuilen

- PATCH 204 bij stille failure: altijd GET na PATCH (ingebouwd in scripts)
- CAL001 named location IDs zijn staging-specifiek: nooit kopieren uit DSC-baseline
- PIM verlopen tijdens script: auth-fout -> opnieuw activeren en hervatten
