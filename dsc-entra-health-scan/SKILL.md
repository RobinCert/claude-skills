---
name: dsc-entra-health-scan
description: >
  Haalt automatisch Entra ID statistieken op uit een DSC klanttenant en voegt
  een Entra Omgevingsoverzicht (Hoofdstuk 4) toe aan het Health Scan Report.
  Geen PowerShell nodig — werkt volledig via Python + één browser-authenticatie.
  Trigger bij: "entra stats health scan", "omgevingsoverzicht toevoegen", "H4 health scan",
  "entra data ophalen voor [klant]", "entra-health-scan", of wanneer iemand Entra-statistieken
  wil toevoegen aan een Health Scan rapport voor een DSC-klant.
  Niet triggeren bij: CarePilot/Vertimart klanten, CP-nummers, of werkzaamheden buiten DSC.
---

# DSC Entra Health Scan Skill

Automatiseert het ophalen van Entra statistieken en het bijwerken van Health Scan Reports.
Geen PowerShell. Geen handmatig kopiëren. Één commando, één browser-tap.

---

## Bekende DSC-klanten

| Klant | Code | Tenant ID | Klantmap |
|---|---|---|---|
| Woonstad Rotterdam | WSR | f4cd4ee9-43a6-4256-a5e0-016c044746c8 | C:\Drop\DSC\Klanten\WSR - Woonstad Rotterdam |
| Gemeente Huizen | HZN | bc49eac0-d8da-4ed9-b328-91c793d8b02e | C:\Drop\DSC\Klanten\HZN - Gemeente Huizen |
| Regio Gooi en Vechtstreek | RGV | 3d4f9081-0beb-452f-a8cf-7203e3681edc | C:\Drop\DSC\Klanten\RGV - Regio Gooi en Vechtstreek |

Scripts: `C:\Drop\DSC\Scripts\HealthScan\`
Runbook:  Obsidian → DSC/Runbooks/Entra-Stats-Health-Scan.md

---

## Werkwijze

### Stap 1 — PIM activeren (Robin/collega doet dit zelf)

Zeg tegen de gebruiker:

> Activeer PIM **Global Reader** op de [KlantNaam] tenant vóór je verdergaat.
> Ga naar: https://entra.microsoft.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade
> Justificatie: *Health Scan — Entra omgevingsoverzicht*
> Bevestig als PIM actief is.

Wacht op bevestiging voordat je verdergaat.

### Stap 2 — Klantmap bepalen

Als de gebruiker geen pad geeft, vraag dan:
> Welke klant? (RGV / WSR / HZN of volledig pad naar de klantmap)

Lees `klant-config.json` uit de klantmap en extraheer:
- `klant.naam`, `klant.code`, `klant.tenantId`, `klant.outputDir`

### Stap 3 — Python dependencies controleren

```bash
pip show msal requests python-docx 2>/dev/null | grep "^Name" | wc -l
```

Als minder dan 3 packages aanwezig:
```bash
pip install msal requests python-docx -q
```

### Stap 4 — Entra stats ophalen

```bash
python "C:\Drop\DSC\Scripts\HealthScan\get_entra_stats.py" \
  -c "[KlantDir]\klant-config.json"
```

Het script print een device code URL + code. Zeg tegen de gebruiker:

> Open de URL die verschijnt, log in met je DSC-beheerdersaccount voor [KlantNaam],
> en voer de code in. Dit is de enige browser-interactie die nodig is.

Wacht tot het script klaar is (laatste regel = pad naar JSON-output).

### Stap 5 — Health Scan document bijwerken

Zoek het meest recente Health Scan docx:
```bash
ls "[KlantDir]\Health Scan\" | grep -i "health scan" | sort | tail -1
```

Run de document-updater:
```bash
python "C:\Drop\DSC\Scripts\HealthScan\Add-EntraHoofdstuk.py" \
  -i "[gevonden docx pad]" \
  -j "[KlantDir]\Health Scan\[KlantCode]-EntraStats.json"
```

### Stap 6 — Afronden

Meld aan de gebruiker:
- Het pad van het bijgewerkte document (nieuw versienummer)
- Kort overzicht van de key stats (gebruikers, groepen, devices)
- Of er opvallende bevindingen zijn (veel stale users, lege groepen, GA's > 4, open gastbeleid)

---

## Opvallende bevindingen — herken en benoem deze

| Bevinding | Drempelwaarde | Wat te zeggen |
|---|---|---|
| Veel stale users | >20% van enabled | "X% van de actieve accounts heeft zich >90 dagen niet ingelogd — cleanup aanbevolen" |
| Enabled zonder licentie | >10% van enabled | "X actieve accounts hebben geen licentie — controleer service accounts" |
| Lege groepen | >25% van totaal | "X% van de groepen is leeg — opschoning aanbevolen" |
| Inactieve devices | >30% van totaal | "X% van de devices is >90 dagen inactief" |
| Global Admins | >4 | "X Global Admins — aanbevolen max is 2-4 (zie H4.5)" |
| Open gastbeleid | AllowInvitesFrom bevat "AllMembers" of "everyone" | "Reguliere leden mogen gasten uitnodigen — overweeg beperking" |
| CA report-only | >0 | "X CA policies staan in report-only — evalueer naar enforce" |

---

## Foutafhandeling

| Fout | Oorzaak | Oplossing |
|---|---|---|
| `AADSTS50076` / MFA vereist | PIM niet actief of verkeerde tenant | Verifieer PIM, gebruik juiste DSC-account |
| `Insufficient privileges` | Global Reader niet actief of scope ontbreekt | Heractiveer PIM, wacht 2 min en retry |
| `ModuleNotFoundError: msal` | Packages niet geïnstalleerd | `pip install msal requests python-docx` |
| JSON `null`-waarden in gebruikers | `signInActivity` niet opgehaald | Check `AuditLog.Read.All` in de consent — of tenant blokkeert sign-in logs |
| `IndexError` in python-docx | Document mist sectPr | Al gefixed in Add-EntraHoofdstuk.py — update script indien nog fout |
| Device code verlopen (>15 min) | Te lang gewacht | Script opnieuw starten |
| `klant-config.json` niet gevonden | Verkeerd pad | Controleer pad, of maak config aan via New-KlantConfig.ps1 |

---

## Technische details (voor de skill zelf)

- Auth: MSAL device code flow, client ID `1950a258-227b-4e31-a9cf-717495945fc2` (Azure PowerShell public client)
- Scopes: User.Read.All, AuditLog.Read.All, Group.Read.All, Device.Read.All, Directory.Read.All, Policy.Read.All, RoleManagement.Read.Directory
- Lege groepen: `/groups/{id}/members/$count` per groep (~1 req/groep, traag bij 1000+)
- JSON encoding: UTF-8 zonder BOM — python leest met `encoding='utf-8'`
- Document versie-bump: automatisch (v0.4 → v0.5)
- sectPr fix: aanwezig in Add-EntraHoofdstuk.py, regel direct na `Document(dest)`

---

## Voorbeeldgesprekken

**"Entra stats voor RGV toevoegen aan health scan"**
→ PIM-instructie geven → klant-config.json lezen → stats ophalen → document bijwerken → output melden

**"Doe hetzelfde voor Gemeente Huizen"**
→ HZN klantmap gebruiken → zelfde flow

**"Kan je chapter 4 opnieuw genereren met de bestaande JSON?"**
→ Stap 4 overslaan, direct naar stap 5 met de bestaande JSON
