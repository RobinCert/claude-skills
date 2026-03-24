---
name: dsc-entra-health-scan
description: >
  Maakt en/of updatet een DSC Health Scan Report voor een klanttenant.
  Regelt setup, Entra-statistieken ophalen en document aanmaken/bijwerken volledig autonoom.
  Geen PowerShell nodig. Één browser-tap voor authenticatie.
  Trigger bij: "entra stats health scan", "omgevingsoverzicht toevoegen", "H4 health scan",
  "entra data ophalen voor [klant]", "health scan aanmaken voor [klant]",
  "nieuw rapport [klant]", "entra-health-scan", of wanneer iemand een Health Scan Report
  wil aanmaken of bijwerken voor een DSC-klant.
  Niet triggeren bij: CarePilot/Vertimart klanten, CP-nummers, of werkzaamheden buiten DSC.
---

# DSC Entra Health Scan Skill

Volledig geautomatiseerde workflow voor DSC Health Scan Reports.
Regelt setup, authenticatie, statistieken en document — van nul tot rapport.

---

## Bekende DSC-klanten

| Klant | Code | Tenant ID | Klantmap |
|---|---|---|---|
| Woonstad Rotterdam | WSR | f4cd4ee9-43a6-4256-a5e0-016c044746c8 | `C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam` |
| Gemeente Huizen | HZN | bc49eac0-d8da-4ed9-b328-91c793d8b02e | `C:\Drop\DSC\Klanten\HZN - Gemeente Huizen` |
| Regio Gooi en Vechtstreek | RGV | 3d4f9081-0beb-452f-a8cf-7203e3681edc | `C:\Drop\DSC\Klanten\RGV - Regio Gooi en Vechtstreek` |

---

## Werkwijze

### Stap 1 — Setup controleren (altijd als eerste)

Controleer of de scripts aanwezig zijn:

```bash
python -c "from pathlib import Path; p = Path('C:/Drop/DSC/Scripts/HealthScan/get_entra_stats.py'); print('OK' if p.exists() else 'MISSING')"
```

**Als MISSING:**

```bash
gh repo clone RobinCert/DSC "C:\Drop\DSC\Scripts" 2>&1
```

Controleer daarna of de Python dependencies aanwezig zijn:

```bash
pip show msal requests python-docx 2>/dev/null | grep "^Name" | wc -l
```

Als minder dan 3:

```bash
pip install msal requests python-docx -q
```

**Als OK:** ga direct door naar stap 2.

---

### Stap 2 — Klant bepalen

Als de gebruiker geen klant of pad heeft opgegeven, vraag:

> Welke klant? (RGV / WSR / HZN — of geef het volledige pad naar de klantmap)

Bepaal `[KlantDir]` op basis van de bekende klanten tabel of het opgegeven pad.

Controleer of `klant-config.json` aanwezig is:

```bash
python -c "from pathlib import Path; p = Path('[KlantDir]/klant-config.json'); print('OK' if p.exists() else 'MISSING')"
```

**Als MISSING:** meld aan de gebruiker:

> `klant-config.json` niet gevonden in `[KlantDir]`.
> Maak het bestand aan met minimaal:
> ```json
> {
>   "klant": {
>     "naam": "[KlantNaam]",
>     "code": "[KlantCode]",
>     "tenantId": "[TenantId]",
>     "outputDir": "[KlantDir]"
>   }
> }
> ```

Wacht tot de gebruiker bevestigt dat het bestand aanwezig is.

Lees de config en extraheer: `klant.naam`, `klant.code`, `klant.tenantId`, `klant.outputDir`.

---

### Stap 3 — Modus bepalen

Controleer of er al een Health Scan rapport bestaat:

```bash
python -c "
import glob, os
files = glob.glob('[KlantDir]/Health Scan/*Health Scan*.docx')
print(sorted(files)[-1] if files else 'GEEN')
"
```

- **GEEN** → Modus A: nieuw rapport aanmaken (stap 4), daarna statistieken toevoegen (stap 5-7)
- **Bestand gevonden** → Modus B: sla stap 4 over, ga direct naar stap 5

---

### Stap 4 — Nieuw basisrapport aanmaken (alleen Modus A)

Vraag de gebruiker:

> Heb je het klantadres en de contactpersonen bij de hand?
> - Adres (straat + huisnummer)
> - Postcode + stad
> - Contactpersoon 1 t/m 3 (naam + rol, bijv. "Jan Jansen (IT)")
>
> Typ `skip` om placeholders te laten staan.

Als de gebruiker gegevens geeft, gebruik ze in het commando. Als `skip`, draai zonder extra args:

```bash
python "C:\Drop\DSC\Scripts\HealthScan\init_health_scan.py" \
  -c "[KlantDir]\klant-config.json" \
  --adres "[ADRES]" \
  --postcode-stad "[POSTCODE STAD]" \
  --contact-1 "[NAAM (ROL)]" \
  --contact-2 "[NAAM (ROL)]" \
  --contact-3 "[NAAM (ROL)]"
```

Meld het aangemaakte bestand aan de gebruiker. Als er nog placeholders zijn, benoem ze:

> Rapport aangemaakt: `[pad]`
> Nog handmatig in te vullen: `[KLANT_CONTACT_2]`, `[KLANT_ADRES]` (open in Word)

---

### Stap 5 — PIM activeren

Zeg tegen de gebruiker:

> Activeer PIM **Global Reader** op de [KlantNaam] tenant vóór je verdergaat.
> Ga naar: https://entra.microsoft.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade
> Justificatie: *Health Scan — Entra omgevingsoverzicht*
>
> Bevestig hier als PIM actief is.

Wacht op bevestiging.

---

### Stap 6 — Entra statistieken ophalen

```bash
python "C:\Drop\DSC\Scripts\HealthScan\get_entra_stats.py" \
  -c "[KlantDir]\klant-config.json"
```

Het script toont een device code en URL. Zeg tegen de gebruiker:

> Open de URL die verschijnt, log in met je **DSC-beheerdersaccount** voor [KlantNaam],
> en voer de code in. Dit is de enige browser-interactie die nodig is.

Wacht tot het script klaar is. De laatste regel van de output is het pad naar de JSON.

---

### Stap 7 — Hoofdstuk 4 toevoegen aan rapport

Zoek het meest recente rapport:

```bash
python -c "
import glob
files = glob.glob('[KlantDir]/Health Scan/*Health Scan*.docx')
print(sorted(files)[-1] if files else 'GEEN')
"
```

Voeg H4 toe:

```bash
python "C:\Drop\DSC\Scripts\HealthScan\Add-EntraHoofdstuk.py" \
  -i "[gevonden docx pad]" \
  -j "[KlantDir]\Health Scan\[KlantCode]-EntraStats.json"
```

---

### Stap 8 — Afronden

Lees de JSON en meld aan de gebruiker:

- Pad van het bijgewerkte document
- Key stats: totaal gebruikers / enabled / disabled / guests / groepen / devices
- Opvallende bevindingen (zie tabel hieronder)

---

## Opvallende bevindingen

| Bevinding | Drempelwaarde | Wat te zeggen |
|---|---|---|
| Veel stale users | >20% van enabled | "X% van de actieve accounts heeft zich >90 dagen niet ingelogd — cleanup aanbevolen" |
| Enabled zonder licentie | >10% van enabled | "X actieve accounts zonder licentie — mogelijk service accounts, controleer" |
| Lege groepen | >25% van totaal | "X% van de groepen is leeg — opschoning aanbevolen" |
| Inactieve devices | >30% van totaal | "X% van de devices is >90 dagen inactief" |
| Global Admins | >4 | "X Global Admins — aanbevolen max is 2-4 (zie H4.5)" |
| Open gastbeleid | AllowInvitesFrom = `adminsGuestInvitersAndAllMembers` of `everyone` | "Reguliere gebruikers mogen gasten uitnodigen — overweeg beperking tot admins" |
| CA report-only | >0 | "X CA policies staan in report-only — evalueer naar enforce" |

---

## Foutafhandeling

| Fout | Oorzaak | Wat te doen |
|---|---|---|
| `AADSTS50076` / MFA required | PIM niet actief of verkeerde tenant | Verifieer PIM, gebruik juiste DSC-account |
| `Insufficient privileges` | Global Reader scope ontbreekt | Heractiveer PIM, wacht 2 min, retry |
| `ModuleNotFoundError: msal` | pip install niet gedaan | `pip install msal requests python-docx` |
| JSON `null`-waarden in gebruikers | `signInActivity` niet opgehaald | Tenant blokkeert sign-in logs — check `AuditLog.Read.All` consent |
| `IndexError` in python-docx | Document mist sectPr element | Al gefixed in Add-EntraHoofdstuk.py — update script als fout blijft |
| Device code verlopen (>15 min) | Te lang gewacht | Script opnieuw starten |
| `klant-config.json` niet gevonden | Verkeerd pad of ontbreekt | Maak aan (zie stap 2) |
| Template niet gevonden | DSC repo niet gecloned of ander pad | Stap 1 opnieuw uitvoeren |
| `gh: command not found` | gh CLI niet geïnstalleerd | Installeer via `winget install GitHub.cli` |

---

## Technische details

- Auth: MSAL device code flow, client ID `1950a258-227b-4e31-a9cf-717495945fc2` (Azure PowerShell public client)
- Scopes: `User.Read.All`, `AuditLog.Read.All`, `Group.Read.All`, `Device.Read.All`, `Directory.Read.All`, `Policy.Read.All`, `RoleManagement.Read.Directory`
- Lege groepen tellen: 1 API call per groep — traag bij 1000+ groepen (~5 min), normaal gedrag
- Template placeholders: `[KLANT_NAAM]`, `[KLANT_CODE]`, `[KLANT_ADRES]`, `[KLANT_POSTCODE_STAD]`, `[KLANT_CONTACT_1/2/3]`, `[DATUM]`
- Document versie-bump: automatisch (`v0.1 → v0.2`, `v0.4 → v0.5`, etc.)
- JSON output: `[KlantDir]\Health Scan\[KlantCode]-EntraStats.json`

---

## Voorbeeldgesprekken

**"Entra stats voor RGV toevoegen aan health scan"**
→ Setup check → RGV config lezen → bestaand rapport gevonden → PIM instrueren → stats ophalen → H4 toevoegen → bevindingen melden

**"Nieuw health scan rapport aanmaken voor Gemeente Huizen"**
→ Setup check → HZN config lezen → geen rapport gevonden → adres/contacten vragen → rapport aanmaken → PIM instrueren → stats ophalen → H4 toevoegen

**"Kan je chapter 4 opnieuw genereren met de bestaande JSON?"**
→ Setup check → stap 5-6 overslaan → direct H4 toevoegen met bestaande JSON

**"Maak een rapport aan maar stats komen later"**
→ Setup check → rapport aanmaken → stoppen na stap 4
