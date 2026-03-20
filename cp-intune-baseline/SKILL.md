---
name: cp-intune-baseline
description: >
  CarePilot Intune baseline deployment van carepilot.it naar klant-tenants (tandartspraktijken).
  Uitsluitend voor CarePilot/Vertimart klanten -- NIET voor DSC. CA baseline DSC is een aparte skill.
  Trigger bij: "Intune baseline deployen/uitrollen naar [klant]", "baseline importeren bij [praktijk]",
  "nieuwe CarePilot tenant onboarden", "admin consent verlenen aan [tenant]", "export-IntuneBaseline draaien",
  "import-IntuneBaseline draaien", "baseline bijwerken bij alle tenants", "LAPS patchen",
  of wanneer CarePilot/Vertimart en Intune/baseline/onboarding samen voorkomen.
  Niet triggeren bij: DSC, Woonstad Rotterdam, Gemeente Huizen, RGV, CA baseline DSC, Conditional Access
  alleen (zonder Intune-context), of non-CarePilot tenants.
  De skill voert het volledige proces autonoom uit: admin consent checken, export ophalen,
  import draaien via PowerShell scripts, post-import acties in kaart brengen.
---

# CarePilot Intune Baseline -- Deployment Skill

Scope: uitsluitend CarePilot/Vertimart klant-tenants. DSC Conditional Access = aparte skill.

## Authenticatie

Volledig unattended via OAuth2 client credentials -- geen PIM, geen interactieve login.

- App ID: 8cc4209f-ce01-4ee3-ba7b-0f6041f4345c (Control Suite)
- Credentials: C:\Users\Home Mini\workspace\integrations\azure\.env
  - CAREPILOT_APP_CLIENT_ID
  - CAREPILOT_CLIENT_SECRET
  - CAREPILOT_TENANT_ID (brontenant voor export)
- Brontenant (home): carepilot.it (b3a15297-...)
- Tenant IDs doeltenants: C:\Users\Home Mini\workspace\integrations\azure\config\tenant_registry.json

Vereiste: admin consent van de doeltenant (zie Fase 2). Zonder consent falen alle Graph calls.

---

## Scripts

Alle scripts staan in C:\Users\Home Mini\Scripts\CarePilot\ (of vergelijkbaar -- verifieer pad eerst):

| Script | Doel |
|---|---|
| Export-IntuneBaseline.ps1 | Exporteert baseline uit brontenant naar timestamped map |
| Import-IntuneBaseline.ps1 | Importeert meest recente export naar doeltenant |
| _fix_assignments_and_dupes.ps1 | Opruimen duplicaten + assignments herstellen |
| _retry_failed.ps1 | Gefaalde imports opnieuw draaien |
| _retry_ca_azure.ps1 | CA retry voor Azure-beheer policy specifiek |
| Patch-LAPS-DVH.ps1 | LAPS patchen (passwordcomplexity/length/prefix) |
| Patch-LAPS-AllTenants.ps1 | LAPS patchen over alle 12 tenants |

Uitvoeren via Desktop Commander (start_process, shell: cmd):
  powershell.exe -NoExit -File "C:\Users\Home Mini\Scripts\CarePilot\Import-IntuneBaseline.ps1" -TargetTenantId "<TENANT_ID>"

---

## Stap-voor-stap deployment

### Fase 1 -- Voorbereiding (eenmalig per nieuwe tenant)

1. Tenant ID registreren in tenant_registry.json (naam, domain, short_name, active, status)
2. Licenties controleren -- minimaal 1x Business Premium of Intune add-on vereist
3. OSDCloud config bijwerken als dit de 13e+ tenant is

### Fase 2 -- Admin consent verlenen

Admin consent URL sturen naar Global Admin van de doeltenant:

  https://login.microsoftonline.com/<TENANT_ID>/adminconsent?client_id=8cc4209f-ce01-4ee3-ba7b-0f6041f4345c

Vereiste permissies die via consent worden gevraagd:
- DeviceManagementConfiguration.ReadWrite.All
- DeviceManagementServiceConfig.ReadWrite.All
- Policy.ReadWrite.ConditionalAccess
- Application.Read.All (voor CA policy MFA Azure-beheer)

Wacht op bevestiging van Robin dat consent is gegeven voordat je verder gaat.

### Fase 3 -- Export (alleen als baseline gewijzigd is)

Controleer eerst de datum van de meest recente export: Scripts\CarePilot\Baseline-Export\

Als export recent genoeg is, sla dit over. Anders:

  .\Export-IntuneBaseline.ps1

Exporteert uit brontenant b3a15297 naar nieuwe timestamped map.

### Fase 4 -- Import naar doeltenant

  .\Import-IntuneBaseline.ps1 -TargetTenantId "<TENANT_ID>"

Script pikt automatisch de meest recente export op en importeert alles in volgorde.

Wat wordt gedeployed:
- Settings Catalog: 35 policies
- Configuration Profiles: 2
- Compliance Policies: 1
- Autopilot Profiles: 2
- Enrollment Configs (ESP): custom only
- Endpoint Security: via templateId
- Conditional Access: 3-4 (altijd op report-only gezet)

Assignment-logica (automatisch op naam):
- Naam bevat DG  -> allDevicesAssignmentTarget
- Naam bevat UG  -> allLicensedUsersAssignmentTarget
- Geen tag       -> unassigned

### Fase 5 -- Post-import actiepunten (altijd handmatig)

Presenteer dit als checklist aan Robin na afloop van de import:

[ ] Wifi Configuration -- SSID + credentials instellen voor die praktijk
[ ] Wallpaper & Lockscreen -- klant-afbeelding uploaden, policy assignen
[ ] MFA voor Azure-beheer CA -- soms opnieuw consent nodig (Application.Read.All)
[ ] CA policies enforced zetten -- na testen omzetten van report-only naar enforced
[ ] Breakglass account aanmaken -- OID toevoegen als excludeUser aan CA policies
[ ] N-central -- NCentral exclusion policy herconfigureren na N-central setup
[ ] Autopilot profielen -- koppelen aan deployment groep

---

## Uitgesloten policies (nooit geimporteerd)

Zijn al gefilterd in het import-script. Ter referentie:
- Android-gerelateerde policies
- EDR Onboarding (tenant-specifieke encrypted blob)
- BitLocker v1.0 (vervangen door BitLocker excl USB)
- NCentral exclusion (klant-specifiek, na N-central setup handmatig)
- CoreView CA (bevat CP-specifieke named location + OIDs)
- ESP priority 0 (bestaat al in elke tenant)
- Firewall, Remote Desktop, Security Hardening, Printer Configuration (verwijderd uit baseline)

---

## Naamgeving

Naming convention: CP-ITEMNAME-VERSIONNAME (bijv. CP-CompliancePolicy-V1)

---

## Veelvoorkomende situaties

"Intune baseline deployen bij [klant]"
-> tenant_registry.json raadplegen voor tenant ID -> admin consent check -> import draaien -> post-import checklist

"Nieuwe CarePilot tenant onboarden"
-> Fase 1 t/m 5 volledig doorlopen

"Baseline is gewijzigd, uitrollen naar alle tenants"
-> Export draaien -> per tenant import uitvoeren -> gefaalde imports via _retry_failed.ps1

"LAPS patchen bij alle tenants"
-> Patch-LAPS-AllTenants.ps1 draaien

"Admin consent URL voor [tenant]"
-> Tenant ID opzoeken in registry -> URL genereren en aan Robin geven

---

## Bekende valkuilen

- Geen admin consent: alle Graph calls falen met 401/403 -- altijd als eerste checken
- Application.Read.All ontbreekt soms: CA policy MFA Azure-beheer faalt apart, gebruik _retry_ca_azure.ps1
- Duplicaten na herhaalde import: gebruik _fix_assignments_and_dupes.ps1
- CA policies komen altijd op report-only binnen -- Robin moet handmatig naar enforced zetten na testen
- ESP priority 0 niet importeren -- bestaat al, overschrijven breekt enrollment flow
