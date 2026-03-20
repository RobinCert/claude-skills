# Claude Skills — ModernStack / DSC

Verzameling van Claude Code skills voor gebruik door Robin Chin-A-Teh en DSC-collega's.

## Beschikbare skills

| Skill | Omschrijving | Voor wie |
|---|---|---|
| `ms365-tenant-manager` | M365 tenant admin — CA policies, users, Exchange, Teams, security | Iedereen |
| `senior-devops` | CI/CD, IaC (Bicep/Terraform), Azure, containerization, monitoring | Iedereen |
| `liquid-glass` | Liquid Glass UI/UX effects (Apple WWDC 2025) | Frontend developers |
| `obsidian-manager` | Beheert de Pegasus Obsidian vault (notes, hub-notes, frontmatter, reorganisatie) | Robin |
| `dsc-ca-baseline` | DSC CA baseline go-live workflow (WSR/HZN/RGV) | DSC-team only — zie opmerking |
| `cp-intune-baseline` | CarePilot Intune baseline deployment naar klant-tenants (tandartspraktijken) | CarePilot-team only — zie opmerking |
| `osdcloud-deployer` | OSDCloud USB deployment en Autopilot device registratie voor CarePilot klanten | CarePilot-team only — zie opmerking |
| `pegasus-reporter` | Genereert professionele klantrapportages (.docx) vanuit de Pegasus Obsidian vault | Robin |

> **dsc-ca-baseline** vereist specifieke lokale setup: scripts op `C:\Drop\DSC\Scripts\Template\`, klant-configs op `C:\Drop\DSC\Klanten\`. Niet bruikbaar zonder die structuur.

> **cp-intune-baseline** en **osdcloud-deployer** vereisen toegang tot de CarePilot Control Suite app en de bijbehorende scripts. Neem contact op met Robin voor onboarding.

---

## Installatie

```powershell
# Alle skills installeren
.\install.ps1

# Specifieke skills installeren
.\install.ps1 -Skills "ms365-tenant-manager,senior-devops"
```

Daarna Claude opnieuw opstarten. Skills zijn beschikbaar in elke nieuwe sessie.

**Handmatig:** kopieer de gewenste skill-map naar `%USERPROFILE%\.claude\skills\`

---

## Skill toevoegen of aanpassen

1. Maak een map aan met de naam van de skill
2. Voeg een `SKILL.md` toe met YAML frontmatter (`name`, `description`)
3. Commit en push
4. Collega's draaien `.\install.ps1` opnieuw

---

## Beheer

Eigenaar: Robin Chin-A-Teh — robin@modernstack.nl
