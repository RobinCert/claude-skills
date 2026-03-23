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

# DSC CA Migratie -- Overlap Analyse en Carryover Skill

Scope: analyse en migratie van BESTAANDE tenant CA policies naar de DSC baseline.
Dit is een aparte workflow bovenop de reguliere Phase 1-5 go-live (dsc-ca-baseline skill).

---

## Bekende DSC-klanten

| Klant | Code | Tenant ID | Config |
|---|---|---|---|
| Woonstad Rotterdam | WSR | f4cd4ee9-43a6-4256-a5e0-016c044746c8 | C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json |
| Gemeente Huizen | HZN | bc49eac0-d8da-4ed9-b328-91c793d8b02e | C:\Drop\DSC\Klanten\HZN - Gemeente Huizen\klant-config.json |
| Regio Gooi en Vechtstreek | RGV | 3d4f9081-0beb-452f-a8cf-7203e3681edc | C:\Drop\DSC\Klanten\RGV - Regio Gooi en Vechtstreek\klant-config.json |

Scripts staan in: C:\Drop\DSC\Scripts\Template\
Launcher: C:\Drop\DSC\Scripts\Run-CaMigratie.ps1

---

## Workflow overzicht (2 stappen)

### Stap 1: Analyse (Analyze-CaMigratie.ps1) -- geen PIM nodig
- Haalt ALLE CA policies op uit de tenant (read-only)
- Classificeert: DSC baseline (^CA[DLUP]\d{3}) vs bestaand vs workshop
- Berekent similarity scores per featureset (gewogen, 14 features)
- Genereert HTML rapport + JSON mapping in outputDir
- Scores: >= 70 = "Uitschakelen na go-live", 50-69 = "Review vereist", < 50 = "Behouden"
- Output: `{CODE}-CA-Migratie-Analyse-{timestamp}.html` + `{CODE}-CA-Migratie-Mapping-{timestamp}.json`

### Stap 2: Carryover (Apply-CaExclusionCarryover.ps1) -- PIM vereist voor live
- Leest de JSON mapping uit stap 1
- Voegt exclusions van bestaande policies met score >= 70 toe aan de DSC baseline equivalenten
- Altijd eerst dry-run, dan live na goedkeuring Robin
- Merge is additief: bestaande exclusions worden NOOIT overschreven
- Verificatie ingebouwd: GET na PATCH, controle op "Merge OK" in output

---

## Auth -- altijd delegated (verplicht)

DSC-klanten: app registration (client_credentials) werkt NIET. Altijd delegated:
- Stap 1 (Analyse): read-only scopes (Policy.Read.All, Directory.Read.All)
- Stap 2 dry-run: read-only scopes
- Stap 2 live: write scopes (Policy.ReadWrite.ConditionalAccess erbij)

Het script roept Connect-MgGraph aan -- Robin klikt Accept in de browser-popup.
PIM voor live: Conditional Access Administrator of Global Administrator.
Waarschuw VOOR live: "Er verschijnt een browser-popup -- klik Accept. Zorg dat PIM actief is."

---

## Scripts uitvoeren via Desktop Commander

Gebruik mcp__Desktop_Commander__start_process, shell: cmd. Altijd -NoExit.

### Via launcher (aanbevolen -- interactief):
```
powershell.exe -NoExit -File "C:\Drop\DSC\Scripts\Run-CaMigratie.ps1"
```

### Stap 1 direct:
```
powershell.exe -NoExit -File "C:\Drop\DSC\Scripts\Template\Analyze-CaMigratie.ps1" -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json"
```

### Stap 2 dry-run:
```
powershell.exe -NoExit -File "C:\Drop\DSC\Scripts\Template\Apply-CaExclusionCarryover.ps1" -ConfigPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\klant-config.json" -MappingPath "C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam\WSR-CA-Migratie-Mapping-{timestamp}.json" -DryRun $true
```

### Stap 2 live:
```
powershell.exe -NoExit -File "C:\Drop\DSC\Scripts\Template\Apply-CaExclusionCarryover.ps1" -ConfigPath "..." -MappingPath "..." -DryRun $false
```

Output lezen via read_process_output. Wacht op "=== KLAAR ===" in de output voor stap 1.
Stap 2 live: wacht op bevestiging van Robin na dry-run.

---

## Stap-voor-stap uitvoering

### Stap 1: Analyse draaien
1. Lees klant-config.json: bepaal golive.fase en workshopPolicies
2. Start Analyze-CaMigratie.ps1 via Desktop Commander
3. Wacht op "=== KLAAR ===" in output
4. Lees het HTML rapport (zoek naar outputDir in de output)
5. Lees de JSON mapping (zoek het .json pad in de output)
6. Bespreek bevindingen met Robin:
   - Hoeveel DSC baseline policies gevonden?
   - Welke bestaande policies hebben hoge overlap-score (>= 70)?
   - Welke exclusions zijn voorgesteld voor carryover?
7. Bevestig of de mapping klopt of aanpassing nodig is
8. Als de mapping OK is: ga naar stap 2 (carryover)

### Stap 2: Carryover uitvoeren
1. Altijd eerst dry-run: start Apply-CaExclusionCarryover.ps1 -DryRun $true
2. Lees de dry-run output:
   - Welke users/groepen worden toegevoegd per DSC baseline policy?
   - "Zou X users + Y groepen toevoegen" per entry
3. Bevestig met Robin: "Ziet dit er goed uit? Dan live uitvoeren."
4. PIM-waarschuwing: "Zorg dat PIM actief is. Er verschijnt een browser-popup."
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
  De analyse herkent CAL001 als DSC baseline, maar de inhoud (location ranges) verschilt per klant.
- Workshop policies (config.workshopPolicies) worden nooit aangeraakt -- ze staan in de analyse maar
  zijn gemarkeerd als "Workshop" en worden uitgesloten van carryover.
- Score >= 70 is een voorstel, geen garantie. Robin beslist altijd of carryover plaatsvindt.
- Merge is additief: als een exclusion al aanwezig is in de DSC baseline policy, wordt die overgeslagen
  (geen duplicaten). Verificatie via "Al aanwezig -- Overgeslagen" in de output.
- PATCH 204 silent failure: scripts doen altijd een GET na elke PATCH om te verifiëren (ingebouwd).
- PIM verlopen tijdens script: auth-fout -> Robin heractiveer PIM -> script opnieuw starten.
- De JSON mapping bevat alleen entries met score >= 70 EN minimaal één exclusion om over te zetten.
  Bij lege carryoverMapping: geen actie nodig (of de bestaande policies hebben geen exclusions).
