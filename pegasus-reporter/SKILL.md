---
name: pegasus-reporter
description: >
  Genereert professionele klantrapportages (Word .docx) vanuit de Pegasus
  Obsidian vault voor Robin Chin-A-Teh. Gebruik deze skill altijd wanneer
  Robin vraagt om: een rapportage maken voor een klant, werkzaamheden
  samenvatten voor [klant], activiteitenverslag genereren, maandrapport of
  kwartaalrapport aanmaken, of een overzicht van gedane werkzaamheden opstellen.
  Trigger ook bij: "maak een rapport voor DSC/CarePilot", "samenvatting van
  wat ik gedaan heb bij [klant]", "activiteitenverslag [klant]",
  "maandrapportage", "kwartaaloverzicht werkzaamheden", "wat heb ik deze maand
  gedaan bij [klant]", "stuur rapport naar klant".
  Niet gebruiken voor: interne notities, runbooks, of technische documentatie.
---

# Pegasus Reporter — Klantrapportage

Genereert een professionele activiteitenrapportage voor de klant op basis van
werkzaamheid-notes uit de Pegasus Obsidian vault.

## Output

Een `.docx` Word document met:
- Voorpagina (klant, periode, datum, branding)
- Managementsamenvatting
- Overzichtstabel van uitgevoerde werkzaamheden
- Details per werkzaamheid (doel, aanpak, resultaat, vervolgstappen)
- Open actiepunten / aanbevelingen

Opgeslagen in: `C:\Users\Home Mini\Documents\Pegasus\Output\`
Bestandsnaam: `<KLANTCODE>-Activiteitenrapportage-<PERIODE>.docx`

---

## Templates — gebruik altijd de klant-specifieke template

### DSC — gebruik de officiële DSC Word template

**Template:** `C:\Users\Home Mini\Documents\Pegasus\Templates\DSC\Word\High_en_Low_LevelDesign.docx`

DSC branding:
- Font: **Poppins** (koppen), **AktivGroteskW06-Light** (body)
- Kleur: **#06BBC1** (DSC teal)
- Paragraafstijlen: `Kop 1 zonder nummering DSC`, `Kop 2 zonder nummering DSC`, `Kop 3 zonder nummering DSC`
- Versietabel verplicht: `Versie | Datum | Auteur | Wijzigingen`

Werkwijze — template als basis gebruiken (unpack → edit XML → repack):
```bash
# Beschikbaar via docx skill scripts
python scripts/office/unpack.py "C:\Users\Home Mini\Documents\Pegasus\Templates\DSC\Word\High_en_Low_LevelDesign.docx" C:\Tmp\dsc-rapport-unpacked\
# ... XML bewerken ...
python scripts/office/pack.py C:\Tmp\dsc-rapport-unpacked\ "C:\Users\Home Mini\Documents\Pegasus\Output\WSR-Activiteitenrapportage-2026-03.docx" --original "C:\Users\Home Mini\Documents\Pegasus\Templates\DSC\Word\High_en_Low_LevelDesign.docx"
```

### CarePilot — nog geen officiële template

Er zijn nog geen CarePilot-templates in de vault. Gebruik tot die tijd de `docx` npm library met ModernStack branding:
- Font: **Calibri**
- Kleur: **#1F4E79** (ModernStack blauw)
- Vraag Robin of er CP-templates beschikbaar zijn.

---

## Werkwijze

### Stap 1 — Bepaal scope

Vraag Robin (als niet opgegeven):
- **Klant:** DSC / CarePilot / beide
- **Periode:** bijv. "maart 2026", "Q1 2026", "afgelopen 2 weken"
- **Toon:** formeel (voor directie/management) of beknopt (voor projectmanager)

### Stap 2 — Werkzaamheden ophalen uit Obsidian

Lees de werkzaamheid-notes voor de opgegeven klant en periode via `Read`:

```
# DSC werkzaamheden
C:\Users\Home Mini\Documents\Pegasus\Pegasus\DSC\Werkzaamheden\

# CarePilot werkzaamheden
C:\Users\Home Mini\Documents\Pegasus\Pegasus\Carepilot\Werkzaamheden\
```

Filter op datum via de frontmatter of bestandsnaam (formaat: `<NAAM>-YYYY-MM-DD.md`).

Lees ook relevante notes:
- Meetingnotulen: `Pegasus/MeetingNotes/`
- Open actiepunten uit werkzaamheden (`vervolgstappen` sectie)

### Stap 3 — Structureer de inhoud

Per werkzaamheid haal je op uit de note:
- **Datum** (frontmatter of bestandsnaam)
- **Doel** (wat was het doel van de werkzaamheid)
- **Aanpak** (werkwijze / uitgevoerde stappen — compact samenvatten)
- **Resultaat** (wat is bereikt / opgeleverd)
- **Vervolgstappen** (openstaande acties)

### Stap 4 — Word document genereren

Genereer het document via Node.js met de `docx` npm library.
Script schrijven naar `C:\Tmp\build-rapport.js` en uitvoeren via Desktop Commander:

```bash
cd /d C:\Drop\DSC && node C:\Tmp\build-rapport.js
```

---

## Document structuur

```
[VOORPAGINA]
  Logo-balk (ModernStack blauw #1F4E79)
  Klant naam (groot)
  "Activiteitenrapportage"
  Periode + datum

[MANAGEMENT SAMENVATTING]
  2-4 bullet points — highlights van de periode
  Aantal werkzaamheden uitgevoerd
  Open actiepunten tellen

[OVERZICHT WERKZAAMHEDEN]
  Tabel: Datum | Onderwerp | Status | Resultaat (compact)

[DETAILS PER WERKZAAMHEID]
  Per item: Doel / Aanpak / Resultaat / Vervolgstappen

[AANBEVELINGEN & VERVOLGSTAPPEN]
  Gegroepeerde open acties
  Eventuele aanbevelingen van Robin

[VOETTEKST]
  "ModernStack | robin@modernstack.nl | Vertrouwelijk"
```

---

## Stijl en toon

- **Taal:** Nederlands
- **Formeel:** gebruik "wij" voor ModernStack, "u" / klantnaam voor klant
- **Technisch niveau:** aanpassen op ontvanger
  - Directie/management → hoog over, nadruk op resultaat en impact
  - IT-projectmanager (bijv. Merel Krielaart bij DSC) → meer detail, maar geen script-details
- **Geen interne notities** — strip alle interne opmerkingen, debug-stappen en tijdelijke aantekeningen

### Formuleringen

| In note | In rapport |
|---|---|
| "script gefixed" | "PowerShell-script gecorrigeerd en gevalideerd" |
| "uitgerold" | "succesvol uitgerold naar productieomgeving" |
| "gefixt / opgelost" | "issue geïdentificeerd en verholpen" |
| "TODO / nog doen" | → naar sectie Vervolgstappen |
| "Robin doet X nog" | → naar sectie Vervolgstappen als open actie |

---

## docx npm — basisstructuur

```javascript
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
        Header, Footer, PageNumber, TabStopType, TabStopPosition } = require('docx');
const fs = require('fs');

// Kleur palet
const BLAUW = "1F4E79";
const LICHTBL = "D6E4F0";

const doc = new Document({
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 }, // A4
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    // headers / footers / children hier
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync("C:\\Users\\Home Mini\\Documents\\Pegasus\\Output\\rapport.docx", buf);
  console.log("OK: " + Math.round(buf.length / 1024) + " KB");
});
```

Script uitvoeren via Desktop Commander (cmd shell, vanuit C:\Drop\DSC waar node_modules staat):
```json
{
  "command": "cd /d C:\\Drop\\DSC && node C:\\Tmp\\build-rapport.js",
  "shell": "cmd"
}
```

---

## Referenties

- Werkzaamheid-format: `Pegasus/DSC/Werkzaamheden/WSR-Robopack-App-Audit-2026-03-16.md`
- Output map: `C:\Users\Home Mini\Documents\Pegasus\Output\`
- docx npm is globaal geïnstalleerd (v9.6.1) en beschikbaar via node_modules in `C:\Drop\DSC`
- CarePilot klanten: 12 tandartspraktijken onder carepilot.it
- DSC klanten: Woonstad Rotterdam, Gemeente Huizen, Regio Gooi en Vechtstreek
- DSC contactpersoon: Merel Krielaart (projectmanager)
