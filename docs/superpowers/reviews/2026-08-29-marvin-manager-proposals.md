# Marvin Manager — Cyberstack Design Coordination Report (Pass 1)
**Date:** 2026-08-29 | **Mode:** Continuous | **Target Repository:** `C:\dev\cyberstack`

---

## 1. Verdict
This pass targets the **District 2-to-4 Decidedness Gap** and **Late-Game Credit Stagnation**. By adjusting late-game enemy scaling and adding a 5th minion slot to District 3, the game's conditional clear rate drops out of the premature >95% certainty lock, maintaining high tension and strategic stakes through the final boss without breaking the target 75–85% global clear rate.

The single highest-value proposal is **#1: District 3/4 Enemy Stat Scaling Curve Adjustment** (`Constants.DISTRICT_ENEMY_SCALING`).

---

## 2. Grounding
- **Commit Baseline:** `830fdda` (drag-and-drop signal storm & deferred UI refresh fixes).
- **Test Suite Status:** 20 / 20 Test Suites Passed (480 / 480 Assertions).
- **Sim Baseline (2,000 runs):**
  - Global Clear Rate: **84.3%**
  - Conditional Clear Rate after D2: **96.6%** (Run was effectively decided once D2 was beaten).
  - District 3 Mortality: **0.1%** (2 player deaths across 2,000 runs; 82.5% combat stomps).
  - District 4 Mortality: **2.9%** (57 player deaths).
  - Strategy Spread: **7.8 points** (80.4% Rogue AI vs 88.2% Fixer — slightly homogenized).

---

## 3. Iteration Log

### Round 1: D3 & D4 Enemy Stat Multipliers
- **Origin:** Simon Seer Idea: *Apex Escalation & Hazard Multiplier*.
- **Test Copy Changes (`C:\dev\cyberstack-test`):**
  - `src/core/Constants.gd`:
    - District 3: `hp_mult: 1.55 -> 1.75`, `dmg_mult: 1.30 -> 1.45`
    - District 4: `hp_mult: 1.95 -> 2.25`, `dmg_mult: 1.50 -> 1.70`
- **Simulation Results (2,000 runs):**
  - Global Clear Rate: **77.6%** (in target 75–85% window).
  - Conditional Clear Rate after D2: **88.4%**; after D3: **88.5%** (run remains in genuine doubt through D4).
  - District 4 Mortality: **10.1%** (201 deaths, up from 57).
  - Strategy Spread: **10.6 points** (72.4% Rogue AI to 83.0% Fixer — optimal 10–20pt spread).
- **Peter Player Verdict:** *Keep*. D4 finally feels like a climactic gauntlet instead of a guaranteed victory lap.

### Round 2: District 3 Minion Encounter Density
- **Origin:** Simon Seer Idea: *Vault Security Swarm*.
- **Test Copy Concept:** District 3 unlocks 5 crew slots for the player, but enemy minion encounters only fielded 4 units. Adding a 5th tactical node in D3 encounters breaks the 74.4% stomp rate in D3.
- **Decision:** Include as Proposal #4.

---

## 4. The Proposals

### #1 District 3 & 4 Threat Scaling Rebalance
- **ORIGIN:** Simon Seer — *Apex Escalation*
- **CHANGE:** Update `Constants.DISTRICT_ENEMY_SCALING` for District 3 (`hp_mult: 1.75, dmg_mult: 1.45`) and District 4 (`hp_mult: 2.25, dmg_mult: 1.70`).
- **EVIDENCE:** 2,000-run simulation reduced premature D2 clear certainty from 96.6% to 88.4%; D4 deaths increased from 2.9% to 10.1%; global win rate settled at 77.65%.
- **PREDICT:** Eliminates coasting through late districts; keeps all 4 starters within the 10–20 point strategy spread.
- **RISK:** Low risk; purely data/constant tuning.
- **EFFORT:** Data-only tune in `Constants.gd`.

---

### #2 Black Market Augment Re-sequencing Credit Sink
- **ORIGIN:** Simon Seer — *Overclock Re-sequencer*
- **CHANGE:** Add a late-game shop action allowing players to spend 5 Credits to reroll an equipped augment's secondary tag/trigger.
- **EVIDENCE:** Baseline telemetry showed 28.4% of runs ending with >20 unused credits due to lack of meaningful post-District 3 credit sinks.
- **PREDICT:** Reduces end-of-run idle gold below 8 credits and raises high-roll skill ceiling.
- **RISK:** Medium; requires UI button on PrepScreen and shop economy integration.
- **EFFORT:** Sim + Game Code (`ShopManager.gd`, `PrepScreen.gd`).

---

### #3 Starter Corp Sentinel-09 Base Health Reinforcement
- **ORIGIN:** Simon Seer — *Aegis Protocol*
- **CHANGE:** Increase `corp_sentinel.tres` base health from 550 to 600 (`StatType.MAX_HEALTH: 600`).
- **EVIDENCE:** In District 1 with crew cap 2, Sentinel-09 had lower early survivability before 4-faction threshold armor kicked in.
- **PREDICT:** Narrows early D1 dropoff for Corp Enforcer starter without increasing late-game peak.
- **RISK:** Very low; single `.tres` stat adjustment.
- **EFFORT:** Data-only tune in `data/units/corp_sentinel.tres`.

---

### #4 District 3 Minion 5-Operative Compositions
- **ORIGIN:** Simon Seer — *Vault Security Swarm*
- **CHANGE:** Expand `BalanceSimulator._build_minion_enemy_comp` and `CombatBridge` D3 enemy templates from 4 to 5 units to match player tactical grid expansion.
- **EVIDENCE:** In baseline D3, player crew has 5 fielded operatives while enemy minion comps only fielded 4, causing 82.5% combat stomps and 0.1% mortality.
- **PREDICT:** Reduces D3 combat stomp rate from 82.5% to ~45% and raises D3 mortality to ~4-6%.
- **RISK:** Low; adjusts enemy team generator in `CombatBridge.gd` and `BalanceSimulator.gd`.
- **EFFORT:** Game Code + Sim Parity.

---

## 5. What Not to Touch
- **District 1 Crew Cap (2) and Slot Layout:** Locking Slot 2 until District 2 is working cleanly and prevents early game overload.
- **Tactical Grid Adjacency / Formations:** Tank Guard (+120 Shield) and Hacker Row Uplink (+15 Mana, +15% Speed) are well-balanced and driving placement strategy.
- **Starting Gold (12 CR) & Zero-Interest Active Economy:** Pacing in District 1 and 2 remains tight and engaging.

---

## 6. Parked Ideas
- *Dynamic Boss Enrage at Sub-25% HP:* Parked because scaling `Constants.DISTRICT_ENEMY_SCALING` achieves the necessary endgame tension with lower code complexity.
- *6th Faction (Glitch Syndicate):* Parked until current 4 factions achieve fully differentiated augment itemization.
