---
name: osdcloud-deployer
description: >
  CarePilot OSDCloud USB deployment en Autopilot device registratie voor
  tandartspraktijken. Gebruik deze skill altijd wanneer Robin vraagt om:
  een device uitrollen naar een CarePilot klant, OSDCloud USB aanmaken of
  bijwerken, Autopilot hash uploaden, Windows 11 installeren via WinPE,
  offline ESD op USB zetten, of troubleshooten van een OSDCloud deployment.
  Trigger ook bij: "rol dit device uit naar [klant]", "OSDCloud USB setup",
  "Autopilot registratie mislukt", "device uitrollen", "Windows 11 installeren
  via USB", "ESD op USB", "Start-CarePilotOSD", "WinPE menu".
  Niet gebruiken voor: DSC klanten, CA baseline, Intune baseline import
  (dat is cp-intune-baseline), of niet-CarePilot tenants.
---

# OSDCloud Deployer — CarePilot

## Concept

```
USB boot → WinPE → klantmenu → hash upload Autopilot → Windows 11 installatie → OOBE → Intune baseline
```

- **Offline ESD** op USB — geen afhankelijkheid van internetsnelheid op locatie
- **Windows 11 24H2 nl-nl** (26100.4349, 4338 MB) op `D:\OSDCloud\OS\`
- **Autopilot hash** wordt automatisch geüpload via de CarePilot app (Graph API)
- **12 tandartspraktijken** beschikbaar in het keuzemenu

---

## Scripts

| Script | Pad | Doel |
|---|---|---|
| `Start-CarePilotOSD.ps1` | `Scripts\CarePilot\OSDCloud\` | Hoofdmenu — tenant keuze, hash, OSDCloud start |
| `Register-AutopilotDevice.ps1` | `Scripts\CarePilot\OSDCloud\` | Autopilot registratie via Graph API |
| `Tenant-Config.ps1` | `Scripts\CarePilot\OSDCloud\` | Tenant IDs voor alle 12 klanten |
| `Config.ps1` | `Scripts\CarePilot\OSDCloud\` | Credentials (client secret — **niet in git**) |

> Lokaal pad: `C:\Users\Home Mini\Documents\Pegasus\Scripts\CarePilot\OSDCloud\`

---

## USB aanmaken (eenmalig)

### Vereisten
- USB stick ≥ 32 GB (USB 3.0 aanbevolen)
- PowerShell als Administrator op home-mini
- Internet voor OSDCloud module + ESD download

### Stap 1 — WinPE USB aanmaken

```powershell
Install-Module OSD -Force -SkipPublisherCheck
Import-Module OSD
New-OSDCloudUSB -WorkspacePath "C:\OSDCloud"
```

### Stap 2 — Scripts op USB kopiëren

```powershell
$USB  = "D:"   # pas aan als USB andere letter heeft
$Dest = "$USB\OSDCloud\Autorun"
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

$Scripts = "C:\Users\Home Mini\Documents\Pegasus\Scripts\CarePilot\OSDCloud"
Copy-Item "$Scripts\Start-CarePilotOSD.ps1" -Destination $Dest
Copy-Item "$Scripts\Config.ps1"              -Destination $Dest
```

### Stap 3 — Offline ESD op USB zetten (Windows 11 24H2 nl-nl)

```powershell
Import-Module OSD -Force
$os   = Get-OSDCloudOperatingSystems |
        Where-Object { $_.Name -match "24H2" -and $_.Language -eq "nl-nl" -and $_.Activation -eq "Retail" } |
        Select-Object -First 1
$dest = "D:\OSDCloud\OS"
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$file = Join-Path $dest (Split-Path $os.Url -Leaf)

Start-BitsTransfer -Source $os.Url -Destination $file -DisplayName "Win11 24H2 nl-nl" -Asynchronous

# Voortgang checken:
Get-BitsTransfer | Where-Object { $_.DisplayName -eq "Win11 24H2 nl-nl" } | Format-List JobState, BytesTransferred, BytesTotal

# Afronden als JobState = Transferred:
Get-BitsTransfer | Where-Object { $_.DisplayName -eq "Win11 24H2 nl-nl" } | Complete-BitsTransfer
```

> Huidig ESD op USB: `26100.4349.250607-1500...nl-nl.esd` (4338 MB, gedownload 2026-03-17)
> Bij nieuwere versie: verwijder oud ESD en draai bovenstaand opnieuw.

---

## Device uitrollen (dagelijks gebruik)

### BIOS per merk

| Merk | BIOS openen | Boot menu |
|---|---|---|
| HP | F10 | F9 |
| Dell | F2 | F12 |
| Lenovo | F1 (of Enter → F1) | F12 |
| Asus | F2 | F8 |
| Acer | F2 | F12 |

> **Secure Boot moet UIT** — BIOS → Security → Secure Boot → Disabled → Save & Exit

### Procedure

1. USB stick in het device steken
2. Restart → BIOS openen → Secure Boot **uitschakelen** → opslaan
3. Boot menu openen → USB selecteren als boot device
4. WinPE laadt → CarePilot keuzemenu verschijnt automatisch
5. Verschijnt het menu **niet** automatisch:
   ```powershell
   # Script detecteert drive letter automatisch — probeer D: dan E:
   powershell -ExecutionPolicy Bypass -File D:\OSDCloud\Autorun\Start-CarePilotOSD.ps1
   ```
6. **Juiste klant selecteren** uit het menu (12 opties)
7. Bevestigen → hash upload → Windows 11 installatie start (~15-20 min)
8. Device herstart → OOBE → Autopilot neemt over (toont bedrijfsnaam)
9. Intune rolt policies en apps uit (~30-45 min na eerste login)

**Totale tijd:** 25-45 minuten

---

## Troubleshooting

| Probleem | Oorzaak | Oplossing |
|---|---|---|
| WinPE laadt niet (blauw scherm) | Secure Boot nog aan | BIOS → Security → Secure Boot → Disabled |
| Menu start niet automatisch | startnet.cmd niet gepatcht | Handmatig: `D:\OSDCloud\Autorun\Start-CarePilotOSD.ps1` (ook E: proberen) |
| Drive letter niet gevonden | WinPE assign wisselend | Script detecteert automatisch; anders expliciet D: of E: gebruiken |
| Autopilot upload 403 | Admin consent verlopen/ontbreekt | Consent opnieuw draaien: `https://login.microsoftonline.com/<TENANT_ID>/adminconsent?client_id=8cc4209f-ce01-4ee3-ba7b-0f6041f4345c` |
| Autopilot upload 400 | Intune niet actief in tenant | Controleer Business Premium / Intune licentie |
| Device niet in Intune | Upload gelukt maar verwerking kost tijd | Wacht 15 min, check Autopilot devices in Intune portal |
| Hash ophalen mislukt | Hardware/WinPE issue | Na eerste Windows boot handmatig: `Install-Script Get-WindowsAutoPilotInfo; Get-WindowsAutoPilotInfo -Online` |
| Verkeerde klant gekozen | Fout in menu | Verwijder device bij Autopilot in Intune van verkeerde tenant → script opnieuw |
| BIOS springt terug | CSM/Legacy instelling | Schakel ook CSM uit in BIOS als aanwezig |

---

## HP BIOS instellingen (referentie)

| Instelling | Waarde |
|---|---|
| Secure Boot | Disabled (voor USB boot) — ná deployment weer Enabled |
| Boot Mode | UEFI |
| USB Boot | Enabled |
| TPM | Enabled (TPM 2.0) |
| Fast Boot | Disabled |

---

## Scripts uitvoeren via Desktop Commander

Gebruik `start_process` met `cmd` shell:

```json
{
  "command": "powershell.exe -ExecutionPolicy Bypass -File \"C:\\Users\\Home Mini\\Documents\\Pegasus\\Scripts\\CarePilot\\OSDCloud\\Start-CarePilotOSD.ps1\"",
  "shell": "cmd"
}
```

---

## Gerelateerde runbooks

- `Pegasus/Carepilot/Runbooks/OSDCloud-USB-Setup.md` — volledige USB setup documentatie
- `Pegasus/Carepilot/Runbooks/Autopilot-Deployment.md` — stap-voor-stap deployment
- `Pegasus/Carepilot/Runbooks/Intune-Baseline-Import.md` — baseline import na deployment
