# Simon Seer Content Proposal — Volatile Conduits & High-Stakes Overclocks

**Date:** 2026-09-05  
**Author:** Simon Seer (Content Designer)  
**Topic:** Reactive Conduits, Grid-Synergy Operatives, and High-Stakes Black Market Overclocking  
**Target Gap:** Translates the newly added Dynamic Grid Doctrines and Tactical Conduits from static stat modifiers into interactive combat procs, solves Rogue AI midline durability, and introduces high-stakes grid-expansion trade-offs.

---

## 1. Grounding

* **Commit Reviewed:** Working copy post-conduits & grid slot specializations (`tests/test_grid_conduits_and_unlocks.gd` passing 21/21 suites).
* **Current Balance State:** Global clear rate `84.2%` with a healthy `12.5pt` starter spread (Blitz/Sentinel `88.4%` vs. GLITCH `75.9%`). Idle credit hoarding dropped to `0.9%`.
* **Recent Review Drivers:**
  * **Peter Player Endgame Review (Proposal #2):** Calls for high-stakes risk/reward overclock choices (spending HP/rerolls for explosive spikes).
  * **Peter Player Ten-Axis Finding:** Conduits need active combat legibility (retaliation/feedback) so players feel the socket power during combat steps, not just on the stat sheet.
  * **Bryan Balancer Finding:** Rogue AI (`ai_glitch`) sits at `75.9%` win rate due to slow early-combat ramp; District 1 mortality sits at `0.0%` needing sharper early decision density.

---

## 2. The Ideas

### Idea 1: Arc Discharge Coil — Melee Retaliation Conduit
```
NAME:        Arc Discharge Coil — Reactive Tesla Overclock
TYPE:        augment (Tactical Conduit)
FANTASY:     Turn your frontline anchor's socket into a lethal lightning trap that shocks attackers in melee range.
GAP:         Existing conduits are passive stat sticks (+Shield, +AD, +Speed). None produce visible combat procs or retaliation feedback during the battle.
STATS:       Cost: 4 Credits. Max Charges: 2. Allowed Rows: FRONTLINE (Row 1).
             Stat Modifiers: {5: 150.0, 4: 15.0} (+150 Max Shield, +15 Armor). Theme Color: #00F0FF (Cyan).
SIGNATURE:   ON_DAMAGE_TAKEN: When the occupant takes damage, discharges 35 electric damage to all adjacent enemies (Internal Cooldown: 1.5s).
EFFECT-CODE: NEW EFFECT ID (proc_conduit_arc_discharge — needs CombatMockArena.gd + BalanceSimulator.gd parity).
SYNERGY:     Empowers Corp Enforcer tanks (Sentinel-09, Iron Wall) and fortified_aegis slot doctrine. Combos with Kinetic/Viral chains.
FAILURE MODE: Clustered frontline tanks could passively delete melee waves without attacking, exacerbating the D1 0% mortality issue. Mitigated by gating to Tier 2+ shops and Cost 4.
```

---

### Idea 2: Hyper-Frequency Siphon — Overclocked Mana Relay Conduit
```
NAME:        Hyper-Frequency Siphon — High-Cadence Neural Tap
TYPE:        augment (Tactical Conduit)
FANTASY:     Push a backline sniper or hacker's neural wiring to the redline, refunding mana on cast for rapid-fire abilities.
GAP:         GLITCH.exe and Rogue AI casters have the lowest baseline win rate (75.9%) because their ability wind-up is too slow against fast physical burst.
STATS:       Cost: 5 Credits. Max Charges: 2. Allowed Rows: BACKLINE (Row 0).
             Stat Modifiers: {6: 35.0, 2: 25.0} (+35 Starting Mana, +25 AP). Theme Color: #FF007F (Magenta).
SIGNATURE:   ON_ABILITY_CAST: When occupant casts their ability, instantly refunds 20 Mana and grants +20% Attack Speed for 4 seconds.
EFFECT-CODE: NEW EFFECT ID (proc_conduit_overclock_siphon — needs CombatMockArena.gd + BalanceSimulator.gd parity).
SYNERGY:     Directly elevates GLITCH.exe, Void Weaver, and Cyber-Witch. Bridges neural_relay doctrine and Neural Hive legendary augment.
FAILURE MODE: Could trigger infinite ability loops on operatives with low max mana. Mitigated by capping refund to 20 Mana and 1 trigger per cast.
```

---

### Idea 3: Vector — Conduit Sapper (Rogue AI Frontline Tank)
```
NAME:        Vector — Conduit Sapper (Rogue AI Tank)
TYPE:        unit (Operative)
FANTASY:     A bulky electromagnetic brawler who channels grid socket power into pulsating defensive barriers for their row allies.
GAP:         The Rogue AI faction has three backline casters/hackers and only one frontline unit, forcing AI comps into awkward off-faction tank splashes.
STATS:       Role: TANK, Faction: ROGUE_AIS, Cost: 3 Credits.
             Base Stats: HP 750, AD 42, AP 35, Armor 25, Shield 120, Speed 30, Starting Mana 20, Max Mana 70, Crit 5%, Evasion 5%.
DIRECTIONAL: SAME_ROW: Allies in the same row gain +15 Ability Power and +10 Starting Mana.
SIGNATURE:   Overload Pulse (ability_overload_pulse): Emits an EMP burst dealing 120 (+0.75 AP) magic damage to adjacent enemies. If Vector is standing on a specialized doctrine slot or active conduit, row allies also gain a 130-point barrier shield for 4s.
EFFECT-CODE: NEW EFFECT ID (ability_overload_pulse — needs CombatMockArena.gd + BalanceSimulator.gd parity).
SYNERGY:     Fills the Rogue AI frontline hole; rewards placing hackers in the same row as Vector; activates amplified AP on adjacent casters.
FAILURE MODE: High innate durability plus AOE shielding could create stall compositions. Kept in check by moderate base attack speed and 70 Max Mana.
```

---

### Idea 4: Flux Resonator — Conduit Extender Chip (Rare Augment)
```
NAME:        Flux Resonator — Sub-Grid Harmonic Chip
TYPE:        augment (Rare Utility Augment)
FANTASY:     An augment that turns tactical conduits into enduring infrastructure rather than quick-burn consumables.
GAP:         Augments and Grid Conduits currently occupy separate mechanical silos. There are zero augments that interact with installed hex overclocks.
STATS:       Tier: RARE, Slot Type: UTILITY, Primary Tag: NEURAL.
             Stat Modifiers: {1: 15.0, 2: 20.0} (+15 AD, +20 AP).
SIGNATURE:   PASSIVE_PROC: Conduits installed on this operative's grid slot gain +1 Maximum Combat Charge. While standing on an active conduit or doctrine slot, unit gains +25% Attack Speed.
EFFECT-CODE: NEW EFFECT ID (proc_flux_resonator — needs CombatMockArena.gd + BalanceSimulator.gd parity).
SYNERGY:     Dramatically increases the credit efficiency of expensive 5-cost conduits (Siphon Bio-Vat, Overclock Siphon); synergizes with Neural 2/4 chains.
FAILURE MODE: If too cheap, players could keep premium conduits alive indefinitely, slowing gold sink velocity. Restricted to Rare tier and 1 equipped per unit.
```

---

### Idea 5: The Underground Splicer — Black Market Hex Expansion Event
```
NAME:        The Underground Splicer — Illegal Grid Calibration
TYPE:        event (Narrative Event)
FANTASY:     Encounter a rogue cyber-engineer who offers taboo, military-spec grid expansion in exchange for raw credits or vital organs.
GAP:         Addresses Peter Player's high-stakes greed mechanic request and adds meaningful mid-run risk/reward node choices.
STATS:       Encounter Districts: District 2 and 3.
             Choice 1: "Purchase Military Overclock" — Requires 10 Credits. Reward: Instantly grants 1 Legendary Conduit (Overcharged Bus or Hyper-Frequency Siphon) and +15 Starting Mana.
             Choice 2: "Siphon Bio-Power for Expansion" — Requires 30.0 Crew HP sacrifice (or Bio-Synthetic role bypass). Reward: Permanently unlocks 1 locked grid slot and calibrates it with a random intrinsic doctrine immediately.
             Choice 3: "Refuse procedure" — Safe bypass. +0 Credits, 0 HP cost.
SIGNATURE:   Push-your-luck event that trades substantial current survival (30 HP) for premature tactical grid expansion.
EFFECT-CODE: DATA-ONLY (Uses standard NarrativeEventResource and EventChoiceResource schemas).
SYNERGY:     Bio-Synthetic role check payoff; allows bold players to unlock 5-unit or 6-unit field formations an entire district early.
FAILURE MODE: Premature slot unlocks could break difficulty curves if the HP penalty isn't punishing enough. Setting cost to 30.0 HP leaves the squad in one-shot danger against the upcoming boss.
```

---

## 3. Sibling Balance & Player Reviews

### Bryan Balancer (`/cyberstack-balance`) Review
* **Arc Discharge Coil (Idea 1):** *"Safe to simulate once the retaliation hook is added to `_step_combatant`. Gating the proc to an internal cooldown of 1.5s ensures enemy boss multi-attacks don't instantly melt the boss. Restricting to Row 1 prevents sniper cheese."*
* **Hyper-Frequency Siphon (Idea 2):** *"Essential medicine for Rogue AIs. GLITCH.exe sitting at 75.9% is our biggest starter outlier. The 20 mana refund on cast is the exact nudge needed to lift GLITCH closer to the 80% median."*
* **The Underground Splicer (Idea 5):** *"Data-only and 100% compliant with existing event validation. The 30 HP sacrifice creates a genuine mortality spike in District 2, helping address our 0% early filter concern."*

### Peter Player (`/cyberstack-userreview`) Review
* **The Underground Splicer (Idea 5):** *"Rating: 5/5. This is the exact high-stakes gamble Cyberstack needs. Sacrificing 30 HP right before the Arcology Boss to unlock an early 5th grid slot is the quintessential roguelite decision."*
* **Arc Discharge Coil (Idea 1):** *"Rating: 4.5/5. Conduits immediately become 300% more exciting when they flash cyan and zap incoming melee rushers. Gives tanks real tactical agency."*
* **Vector (Idea 3):** *"Rating: 4/5. Rogue AI finally gets an authentic brawler that connects hacker row uplinks with frontline defense."*
* **Flux Resonator (Idea 4):** *"Rating: 3.5/5. Solid cross-system bridge, but feels like an augment you draft only when you already have great conduits rolling."*

---

## 4. The Ranked Shortlist

1. **#1 The Underground Splicer (Idea 5 — Event):**  
   *Why #1:* **Data-only**, instantly deployable, fulfills Peter's high-stakes greed mechanic request, and introduces a real D2/D3 mortality threat without code risk.
2. **#2 Arc Discharge Coil (Idea 1 — Tactical Conduit):**  
   *Why #2 beats #3:* Solves the "passive stat stick" problem for conduits by giving frontline sockets visual and mechanical retaliation against attackers.
3. **#3 Hyper-Frequency Siphon (Idea 2 — Tactical Conduit):**  
   *Why #3 beats #4:* Directly targets our lowest-performing starter (GLITCH.exe at 75.9%), lifting caster squad viability into the 80% golden zone.
4. **#4 Vector — Conduit Sapper (Idea 3 — Unit):**  
   *Why #4 beats #5:* Solves Rogue AI's frontline identity crisis while weaving socket doctrines into active ability payouts.
5. **#5 Flux Resonator (Idea 4 — Augment):**  
   *Ranked 5:* Bridges augments and conduits nicely, but relies on existing conduit roll luck to shine.

---

## 5. Implementation Notes

* **Data-Only Candidates (Ready to Author Immediately):**
  * `The Underground Splicer` ([`data/events/event_underground_splicer.tres`](file:///c:/Dev/Cyberstack/data/events/))
* **Effect-Code Candidates (Require Combat & Sim Parity):**
  * `Arc Discharge Coil`: Hook `ON_DAMAGE_TAKEN` retaliation in `CombatMockArena.gd` and `BalanceSimulator.gd`.
  * `Hyper-Frequency Siphon`: Hook `ON_ABILITY_CAST` mana refund in `CombatMockArena.gd` and `BalanceSimulator.gd`.
  * `Vector`: Author unit resource + add `ability_overload_pulse` handler.
