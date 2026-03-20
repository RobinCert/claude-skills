---
name: obsidian-manager
description: >
  Beheert de Pegasus Obsidian vault van Robin Chin-A-Teh. Gebruik deze skill
  altijd wanneer Robin vraagt om: nieuwe notes aanmaken, de vault reorganiseren,
  bestanden taggen of linken, hub-notes maken, frontmatter toevoegen/corrigeren,
  runbooks aanmaken, klantdossiers aanmaken, de graph view verbeteren, losse
  bestanden opruimen, of de vaultstructuur uitleggen. Trigger ook bij:
  "zet dit in Obsidian", "maak een note", "documenteer in de vault",
  "reorganiseer de vault", "link deze notes", "voeg frontmatter toe",
  "nieuwe klant aanmaken in Obsidian", "ruim de vault op".
---

# Obsidian Vault Manager — Pegasus

## Vault locatie

```
C:\Users\Home Mini\Documents\Pegasus\
```

De `.obsidian` config map staat in de vault root. Gebruik **altijd** absolute paden bij filesystem-operaties.

## Tools

- **obsidian-mcp-tools**: voor alle read/write operaties op .md bestanden (get_vault_file, create_vault_file, list_vault_files, append_to_vault_file, show_file_in_obsidian)
- **Desktop Commander (start_process)**: voor file system operaties (verplaatsen, verwijderen, aanmaken van mappen, scripts uitvoeren)

---

## Vaultstructuur

```
Pegasus/                    ← vault root
├── CLAUDE.md               ← Claude Code instructies
├── MEMORY.md               ← auto-memory index
├── Pegasus/                ← georganiseerde notes
│   ├── Index.md            ← centraal knooppunt graph
│   ├── Carepilot/          ← CarePilot klantdossier
│   │   ├── Carepilot.md    ← hub
│   │   ├── Runbooks/       ← 13 runbooks
│   │   ├── Baseline/
│   │   ├── Tenants/
│   │   ├── Contacten/
│   │   └── ...
│   ├── DSC/                ← DSC klantdossier
│   │   ├── DSC.md          ← hub
│   │   ├── Runbooks/       ← CA baseline runbook
│   │   ├── Confluence/     ← DSC Confluence kopie
│   │   ├── Klanten/        ← WSR, HZN, De Regio, Evides
│   │   ├── Contacten/
│   │   └── ...
│   ├── ModernStack/        ← ModernStack intern
│   │   ├── Claude-Skills.md
│   │   └── Claude-Skills-Handleiding.md
│   ├── Prive/
│   ├── MeetingNotes/
│   ├── VoiceNotes/
│   └── Projecten/
├── Scripts/                ← scripts (niet in graph)
│   ├── NCentral/           ← N-central monitoring scripts (oud/PQR)
│   ├── HomeAI/             ← home server setup scripts
│   ├── ModernStack/        ← CV generator, push scripts
│   └── CarePilot/          ← Intune deploy, baseline scripts
├── Tools/                  ← tooling
│   ├── claude-skills/      ← skills repo (git)
│   ├── new_entity.py       ← nieuwe entiteit aanmaken
│   └── ...
├── Templates/              ← Obsidian templates
├── Logs/
├── Mini/
└── Output/
```

---

## Frontmatter standaard

Elke .md note krijgt YAML frontmatter:

```yaml
---
type: hub | runbook | klant | configuratie | hardware | werkzaamheid | referentie | deprecated
klant: carepilot | dsc | prive | algemeen
status: actief | concept | uitgevoerd | deprecated
tags:
  - relevante-tag
---
```

**type-keuze:**
- `hub` — centrale index/overzichtsnote
- `runbook` — stap-voor-stap werkprocedure
- `klant` — klantdossier
- `configuratie` — technische configuratiedocumentatie
- `hardware` — hardware setup/specs
- `werkzaamheid` — uitgevoerde werkzaamheid / taak
- `referentie` — referentiemateriaal, handleidingen
- `deprecated` — verouderd

---

## Wijzigingslog — verplicht voor hardware en configuratie

```markdown
## Wijzigingslog
| Datum | Wat | Door |
|---|---|---|
| YYYY-MM-DD | Omschrijving | Robin (+ Claude) |
```

---

## Nieuwe entiteiten aanmaken

### Via script (aanbevolen)

```powershell
python "C:\Users\Home Mini\Documents\Pegasus\Tools\new_entity.py" --type klant --naam "Naam" --klant-code dsc
```

### Handmatig

1. Maak map aan in `Pegasus/<sectie>/`
2. Maak `<naam>.md` aan met frontmatter
3. Voeg link toe in relevante hub-note
4. Link vanuit `Pegasus/Index.md` als het een nieuw cluster is

---

## Templates

Locatie: `Pegasus/Templates/`

| Template | Gebruik |
|---|---|
| `Runbook-Template.md` | nieuwe runbooks |
| `Klant-Template.md` | nieuwe klantdossiers |
| `Werkzaamheid-Template.md` | uitgevoerde werkzaamheden |
| `Meeting-Template.md` | meetingnotulen |

---

## Hub-notes aanmaken

Hub-notes verbinden clusters in de graph view. Structuur:

```markdown
---
type: hub
klant: <klant>
status: actief
tags:
  - <klant>
  - index
---

# Titel

Korte beschrijving.

## Secties

- [[Link1]] — omschrijving
- [[Link2]] — omschrijving
```

Zorg altijd dat een hub-note vanuit `Pegasus/Index.md` gelinkt wordt.

---

## Scripts organiseren

Scripts (.ps1, .py, .js) horen **niet** als losse bestanden in de vault root of notes-mappen. Organiseer ze in `Scripts/<categorie>/` en maak een `<Categorie>.md` hub-note aan.

```
Scripts/
├── <Categorie>/
│   ├── <Categorie>.md      ← beschrijving + tabel van scripts
│   └── *.ps1 / *.py / *.js
```

---

## Wikilinks

- Gebruik `[[NoteNaam]]` voor interne links
- Gebruik `[[NoteNaam|Weergavenaam]]` als de bestandsnaam anders is dan gewenst
- Verbind verwante notes altijd bidirectioneel waar zinvol
- Elke nieuwe note in `Pegasus/<klant>/` linkt terug naar de hub-note van die klant

---

## Werkwijze bij reorganisatie

1. `list_vault_files` — breng structuur in kaart
2. Identificeer: losse bestanden, notes zonder frontmatter, ongelinkte notes
3. Verplaats scripts naar `Scripts/<categorie>/` via Desktop Commander
4. Voeg/corrigeer frontmatter toe via `create_vault_file` of `patch_vault_file`
5. Maak hub-notes aan voor nieuwe clusters
6. Update `Pegasus/Index.md` met nieuwe links
7. Verwijder lege mappen

---

## Klanten en hun hubs

| Klant | Hub note | Runbooks |
|---|---|---|
| CarePilot | `Pegasus/Carepilot/Carepilot.md` | `Pegasus/Carepilot/Runbooks/` |
| DSC | `Pegasus/DSC/DSC.md` | `Pegasus/DSC/Runbooks/` |
| ModernStack (intern) | `Pegasus/ModernStack/Claude-Skills.md` | n.v.t. |

---

## Memory bijwerken

Bij elke nieuwe klant, device of tool:
1. Maak Obsidian note aan
2. Voeg pointer toe aan `~/.claude/projects/.../memory/MEMORY.md`
3. Update `MEMORY.md` index als er een nieuw memory bestand is
