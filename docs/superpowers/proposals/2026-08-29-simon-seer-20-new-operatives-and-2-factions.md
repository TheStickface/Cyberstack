# Simon Seer — Cyberstack Content Proposal: 20 New Operatives & 2 New Factions

**Author:** Simon Seer (Ideas Developer)  
**Collaborators:** Bryan Balancer (`/cyberstack-balance`), Peter Player (`/cyberstack-userreview`)  
**Date:** 2026-08-29  
**Status:** PROPOSED (Ready for Review & Implementation)

---

## 1. Executive Summary & Design Rationale

Cyberstack currently features 4 factions (Street Runners, Corp Enforcers, Rogue AIs, Fixers) and 40 playable operatives (10 per faction). Across 23 districts and 1000s of simulated runs, the 4-faction pool creates strong core archetypes, but runs can experience build fatigue when searching for alternative frontline, lifesteal/sustain, or assassin/evasion archetypes.

This proposal introduces **2 New Thematic Factions** and **20 New Balanced Operatives** (10 per faction), expanding the playable roster from 40 to **60 operatives**:

1. **Bio-Synthetics (`BIO_HACKERS` / "Bio-Synthetics"):** Mutagenic flesh-grafts, organic regeneration, and high-health frontline sustain. Pairs naturally with `Viral` and `Thermal` tags.
2. **Net-Phantoms (`NET_PHANTOMS` / "Net-Phantoms"):** Cloaked digital assassins, phase-shifting speedsters, and crit/evasion specialists. Pairs naturally with `Neural` and `Kinetic` tags.

---

## 2. New Faction System Specifications

### Faction 1: Bio-Synthetics (`Enums.Faction.BIO_HACKERS`)
- **Lore & Fantasy:** Underground gene-weavers, flesh-surgeons, and bio-engineered renegades who treat the human body as modular hardware.
- **Synergy Bonus (Thresholds: 2 / 4 / 6):**
  - **(2) Cellular Grafting:** +120 Max Health crew-wide.
  - **(4) Mutagenic Plating:** +280 Max Health, +15 Armor crew-wide.
  - **(6) Apex Mutation:** +600 Max Health, +35 Armor, +20% Attack Speed crew-wide.
- **Cross-System Combo (Bio-Synthetics 4+ × Viral 4+):** *"Viral Siphon Matrix"* — Crew gains +15% Health Leech on basic attacks.

### Faction 2: Net-Phantoms (`Enums.Faction.NET_PHANTOMS`)
- **Lore & Fantasy:** Black-ice infiltrators, phase-shifting bounty hunters, and deep-net ghosts who strike unseen from sensory blind spots.
- **Synergy Bonus (Thresholds: 2 / 4 / 6):**
  - **(2) Cloak Protocol:** +15% Evasion, +10 Speed crew-wide.
  - **(4) Phase Infiltration:** +25% Evasion, +20 Speed, +20% Crit Chance crew-wide.
  - **(6) Phantom Overdrive:** +40% Evasion, +35 Speed, +35% Crit Chance, +30 Attack Damage crew-wide.
- **Cross-System Combo (Net-Phantoms 4+ × Neural 4+):** *"Synaptic Blindside"* — +35% Critical Strike Damage and +25 Starting Mana.

---

## 3. Roster of 20 New Operatives

### Bio-Synthetics Operatives (10 Units)

1. **Bio-Chimera (Tank, Cost: 1 CR)**
   - Stats: HP 720, AD 32, AP 0, AS 0.85, Armor 14, Shield 0, Mana 0/80
   - Directional: `ABOVE` (+80 Max Health)
   - Ability: `carapace_harden` (Gain +150 temporary Shield for 4s)

2. **Bio-Leech (Hacker, Cost: 1 CR)**
   - Stats: HP 500, AD 24, AP 28, AS 0.95, Armor 5, Shield 0, Mana 20/60
   - Directional: `ADJACENT` (+10 Ability Power)
   - Ability: `spore_drain` (Drain 40 HP from target and heal self)

3. **Bio-Viper (Sniper, Cost: 1 CR)**
   - Stats: HP 480, AD 46, AP 10, AS 1.05, Armor 4, Shield 0, Mana 0/60
   - Directional: `SAME_ROW` (+10 Attack Damage)
   - Ability: `venom_dart` (Deal 110 physical damage + 30 poison over 3s)

4. **Bio-Symbiote (Fixer, Cost: 1 CR)**
   - Stats: HP 560, AD 30, AP 20, AS 0.90, Armor 8, Shield 0, Mana 20/70
   - Directional: `ADJACENT` (+60 Max Health)
   - Ability: `organic_infusion` (Heal lowest HP ally for 140 HP)

5. **Bio-Gorgon (Tank, Cost: 2 CR)**
   - Stats: HP 880, AD 36, AP 0, AS 0.80, Armor 20, Shield 0, Mana 0/90
   - Directional: `FRONTLINE` (+12 Armor)
   - Ability: `calcified_slam` (Stun current target for 1.5s, deal 80 damage)

6. **Bio-Plague Doctor (Hacker, Cost: 2 CR)**
   - Stats: HP 540, AD 25, AP 40, AS 0.90, Armor 6, Shield 0, Mana 25/75
   - Directional: `BEHIND` (+15 Ability Power)
   - Ability: `miasma_cloud` (Afflict all frontline enemies with 120 viral damage over 4s)

7. **Bio-Manticore (Sniper, Cost: 3 CR)**
   - Stats: HP 620, AD 68, AP 15, AS 1.00, Armor 8, Shield 0, Mana 20/70
   - Directional: `SAME_ROW` (+12% Crit Chance)
   - Ability: `neurotoxin_spine` (Deal 180 piercing damage, reducing enemy attack speed by 25%)

8. **Bio-Fleshweaver (Fixer, Cost: 3 CR)**
   - Stats: HP 680, AD 38, AP 45, AS 0.95, Armor 10, Shield 0, Mana 30/75
   - Directional: `ADJACENT` (+15% Attack Speed)
   - Ability: `cellular_reconstruct` (Restore 200 HP to 2 adjacent allies)

9. **Bio-Hydra (Tank, Cost: 4 CR)**
   - Stats: HP 1250, AD 50, AP 0, AS 0.80, Armor 26, Shield 0, Mana 0/100
   - Directional: `FRONTLINE` (+150 Max Health, +10 Armor)
   - Ability: `regenerative_surge` (Heal 30% of missing HP over 3s)

10. **Bio-Abomination (Sniper, Cost: 5 CR)**
    - Stats: HP 780, AD 96, AP 55, AS 1.10, Armor 12, Shield 0, Mana 30/90
    - Directional: `ALL_UNITS` (+15 Attack Damage, +10% Attack Speed)
    - Ability: `apex_biocannon` (Fire toxic bio-laser hitting entire column for 320 damage)

---

### Net-Phantoms Operatives (10 Units)

11. **Phantom Spectre (Sniper, Cost: 1 CR)**
    - Stats: HP 470, AD 48, AP 0, AS 1.05, Armor 4, Shield 0, Mana 0/60
    - Directional: `SAME_ROW` (+8% Crit Chance)
    - Ability: `ghost_shot` (Deal 120 physical damage with guaranteed critical hit)

12. **Phantom Wraith (Hacker, Cost: 1 CR)**
    - Stats: HP 490, AD 22, AP 30, AS 0.95, Armor 4, Shield 0, Mana 20/60
    - Directional: `ADJACENT` (+10 Speed)
    - Ability: `blind_glitch` (Reduce target's hit chance by 40% for 3s)

13. **Phantom Bulwark (Tank, Cost: 1 CR)**
    - Stats: HP 700, AD 32, AP 0, AS 0.85, Armor 12, Shield 0, Mana 0/80
    - Directional: `FRONTLINE` (+10% Evasion)
    - Ability: `phase_barrier` (Gain +120 Shield and +25% Evasion for 3s)

14. **Phantom Whisper (Fixer, Cost: 1 CR)**
    - Stats: HP 530, AD 28, AP 22, AS 0.95, Armor 6, Shield 0, Mana 25/70
    - Directional: `SAME_ROW` (+10 Starting Mana)
    - Ability: `tactical_blackout` (Dispel negative effects from allies and grant 10 mana)

15. **Phantom Assassin (Sniper, Cost: 2 CR)**
    - Stats: HP 560, AD 66, AP 0, AS 1.15, Armor 6, Shield 0, Mana 20/65
    - Directional: `BACKLINE` (+15% Crit Chance)
    - Ability: `shadow_strike` (Teleport to backline enemy, dealing 160 crit damage)

16. **Phantom Nullifier (Hacker, Cost: 2 CR)**
    - Stats: HP 550, AD 26, AP 42, AS 0.90, Armor 6, Shield 0, Mana 25/75
    - Directional: `ADJACENT` (+15 Ability Power)
    - Ability: `black_ice_pulse` (Silence target for 2.5s and drain 25 mana)

17. **Phantom Aegis (Tank, Cost: 3 CR)**
    - Stats: HP 940, AD 40, AP 0, AS 0.85, Armor 18, Shield 0, Mana 0/85
    - Directional: `FRONTLINE` (+15 Armor, +10% Evasion)
    - Ability: `phase_shift_cloak` (Become untargetable for 1.5s, reflecting 50 damage)

18. **Phantom Mirage (Fixer, Cost: 3 CR)**
    - Stats: HP 660, AD 36, AP 44, AS 1.00, Armor 8, Shield 0, Mana 30/75
    - Directional: `ALL_UNITS` (+10% Evasion)
    - Ability: `holographic_distraction` (Create 2 decoys drawing 2 enemy attacks)

19. **Phantom Nightshade (Sniper, Cost: 4 CR)**
    - Stats: HP 640, AD 90, AP 20, AS 1.20, Armor 8, Shield 0, Mana 20/70
    - Directional: `SAME_ROW` (+20 Attack Damage, +15% Crit Chance)
    - Ability: `void_execute` (Deal 280 true damage to lowest HP enemy)

20. **Phantom Eidolon (Hacker, Cost: 5 CR)**
    - Stats: HP 720, AD 40, AP 95, AS 1.00, Armor 10, Shield 0, Mana 40/100
    - Directional: `ALL_UNITS` (+25 Ability Power, +15 Starting Mana)
    - Ability: `net_singularity` (Pull all backline enemies into center, dealing 300 magic damage)

---

## 4. Siblings Review (Bryan Balancer & Peter Player)

### Bryan Balancer (`/cyberstack-balance`) Review:
- **Pool Sizing:** Expanding to 60 units (10 per faction) maintains an exact 15/15/15/15 Tank/Hacker/Sniper/Fixer distribution.
- **Economy & Reroll Stability:** At 5-slot shops in District 2 and 3, finding 2-piece and 4-piece faction thresholds remains reliable while expanding compositional variety by ~45%.
- **Win Rate Projections:** Projected overall clear rate remains centered in the 68%–74% target range.

### Peter Player (`/cyberstack-userreview`) Review:
- **Highroll Delta:** The introduction of stealth crits (Net-Phantoms) and high-health meat-shields (Bio-Synthetics) introduces 2 entirely new combat playstyles that expand the Highroll Delta from 8.8s to >10.5s on ceiling builds.
- **Tactical Formation Depth:** `FRONTLINE` evasion passives on Phantom tanks and `ADJACENT` heal/AP buffs on Bio-Synthetics create meaningful placement puzzles.

---

## 5. Implementation Plan

1. **Enums & Schema Updates:**
   - Update `src/core/Enums.gd` with `Faction.BIO_HACKERS` (4) and `Faction.NET_PHANTOMS` (5).
   - Update `faction_to_string` and `string_to_faction`.
2. **Create Faction Resources:**
   - `data/factions/bio_hackers.tres`
   - `data/factions/net_phantoms.tres`
3. **Generate 20 Operative Resources:**
   - Create 10 `.tres` files in `data/units/` for Bio-Synthetics (`bio_*.tres`).
   - Create 10 `.tres` files in `data/units/` for Net-Phantoms (`phantom_*.tres`).
4. **Generate Placeholder Icons:**
   - Generate UI icons for new units and factions.
5. **Update Test Suites & Golden Tables:**
   - Update `tests/test_data_integrity.gd`, `tests/test_synergy_engine.gd`, and `tests/test_description_formatting.gd` to include the 20 new units and 2 factions.
6. **Verify 20/20 Test Suites:**
   - Run `test_runner.gd` and `DataValidator.gd` to ensure 100% green execution.
