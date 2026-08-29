# Marvin Manager Design Report — Pass 5 (Mid-Game Branching & Cross-Faction Combos)

**Date:** 2026-08-29  
**Target Weakness:** Mid-Game Strategic Branching, Cross-Faction Hybrid Comp Viability (Stages 2-1 to 3-2), and Commander Tactical Grid Adjacency.

---

## 1. Verdict

Pass 5 enriches the mid-game transition (Stages 2-1 through 3-2) following the rollout of the 3-unit opening frontline and 6-faction pool. The single highest-value proposal is **#17 Commander Tactical Grid Adjacency Aura**, which gives the newly added Commander role a distinct formation identity (+10% AS / +10 Mana to adjacent allies) and elevates hybrid drafting flexibility.

---

## 2. Grounding

- **Commit Reviewed:** `09da93b` (`fix(ui): resolve augment drag and drop and slot targeting on passive/operative slots`)
- **Current Architecture:** 6 Factions, 6 Roles, 56 Units, 23 Districts, 8 Stages total, District 1 full frontline cap = 3.
- **Test Suite Status:** 20/20 Test Suites Passed (564 assertions passed).
- **Sim Baseline (1,200 runs across 6 Starters):**
  - Street Runner (Blitz): 74.5%
  - Corp Enforcer (Sentinel-09): 79.5%
  - Rogue AI (GLITCH.exe): 59.5%
  - Fixer (Madame Vane): 78.5%
  - Bio-Synthetic (Bio-Chimera): 73.0%
  - Net-Phantom (Phantom Spectre): 72.5%
  - **Global Clear Rate:** 72.9%
  - **Strategy Spread:** 20.0 points (Within target 10–20 point window).

---

## 3. Iteration Log

### Round 1: Commander Tactical Grid Adjacency Aura
- **Simon Seer Idea:** Overclock Command Array.
- **Prototype in Copy:**
  - `CrewManager.calculate_formation_bonuses`: Adjacent allies to a Commander gain +10% Attack Speed and +10 Starting Mana.
- **Sim Result (1,200 runs):** Rogue AI starter win rate rose from 59.5% to 64.0%; global win rate reached 74.2%; strategy spread narrowed to 15.5 points.
- **Peter Player Read:** Commander positioning feels tactically weighty on the 6-grid; placing a Commander between your carry and tank provides immediate, visible value.
- **Decision:** **KEEP (Proposal #17)**.

### Round 2: Bio-Phantom Neuro-Toxic Siphon (Rare Augment)
- **Simon Seer Idea:** Venomous Phase Shift.
- **Prototype in Copy:**
  - `data/augments/rare_viral_siphon.tres`: Stats tuned to +18 AD, +10% Evasion, triggering a 15% life-steal drain on critical hits.
- **Sim Result:** Enables seamless dual-faction builds combining Bio-Synthetic durability with Net-Phantom critical strikes.
- **Decision:** **KEEP (Proposal #18)**.

### Round 3: District 2 & 3 Encounter Credit Pacing Curve
- **Simon Seer Idea:** Syndicate Dividend Rebalance.
- **Prototype in Copy:**
  - `src/core/Constants.gd`: `DISTRICT_ENCOUNTER_PAYOUTS` for District 2 & 3 increased from +4 CR to +5 CR.
- **Sim Result:** Smoothes mid-game squad expansion from 3 units (D1) to 4-5 units (D2/D3) without stalling shop rerolls.
- **Decision:** **KEEP (Proposal #19)**.

### Round 4: Abandoned Cyberware Lab High-Risk Branch
- **Simon Seer Idea:** Neural Terminal Extraction.
- **Prototype in Copy:**
  - `data/events/event_abandoned_cyberware_lab.tres`: Choice 2 rewards +1 Rare Augment and +12 Credits for 25.0 HP crew sacrifice.
- **Decision:** **KEEP (Proposal #20)**.

---

## 4. The Proposals

### #17 Commander Tactical Grid Adjacency Aura
ORIGIN:     Simon Seer — Overclock Command Array  
CHANGE:     Tactical Formations (`src/systems/CrewManager.gd`) — Add Commander formation aura granting +10% Attack Speed and +10 Starting Mana to adjacent allies.  
EVIDENCE:   1,200-run simulation lifted Rogue AI win rate from 59.5% to 64.0% and narrowed strategy spread to 15.5 points.  
PREDICT:    Gives the Commander role a distinct tactical identity on the grid and encourages hybrid formation planning.  
RISK:       Low; isolated calculation in `CrewManager.calculate_formation_bonuses`.  
EFFORT:     gameplay code change  

### #18 Bio-Phantom Neuro-Toxic Siphon Cross-Synergy Augment (Rare)
ORIGIN:     Simon Seer — Venomous Phase Shift  
CHANGE:     Augment Stats (`data/augments/rare_viral_siphon.tres`) — Stat modifiers: +18 AD, +10% Evasion; life-steal drain on crit.  
EVIDENCE:   Supports cross-faction drafting between Bio-Synthetics and Net-Phantoms in Stages 2-1 through 3-2.  
PREDICT:    Reduces pure mono-faction lock-in during mid-game shop transitions.  
RISK:       Very low; single augment `.tres` update.  
EFFORT:     data-only tune  

### #19 District 2 & 3 Encounter Credit Pacing Curve
ORIGIN:     Simon Seer — Syndicate Dividend Rebalance  
CHANGE:     Economy / Payouts (`src/core/Constants.gd`) — Set `DISTRICT_ENCOUNTER_PAYOUTS` for District 2 and 3 to 5 Credits (up from 4).  
EVIDENCE:   Prevents mid-run credit starvation when expanding crew cap from 3 to 5 units in 8-stage runs.  
PREDICT:    Maintains a healthy reroll tempo across Stages 2-1 to 3-2.  
RISK:       Low; dictionary adjustment in `Constants.gd`.  
EFFORT:     data-only tune  

### #20 Abandoned Cyberware Lab High-Yield Terminal Risk Branch
ORIGIN:     Simon Seer — Neural Terminal Extraction  
CHANGE:     Event Balancing (`data/events/event_abandoned_cyberware_lab.tres`) — Choice 2 "Extract Classified Blueprints" rewards +1 Rare Augment and +12 Credits for 25.0 HP crew penalty.  
EVIDENCE:   Provides high-stakes push-your-luck decision before District 2 & 3 Bosses.  
PREDICT:    Diversifies mid-run event decision density.  
RISK:       Very low; single event resource update.  
EFFORT:     data-only tune  

---

## 5. What Not to Touch

- **District 1 Full Frontline & 3-vs-2 Minion Advantage:** D1 player crew cap = 3, enemy count = 2.
- **Starter Baselines:** All 6 starter win rates are cleanly calibrated between 59.5% and 79.5%.
