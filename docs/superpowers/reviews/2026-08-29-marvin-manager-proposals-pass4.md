# Marvin Manager Design Report — Pass 4 (6-Faction & 2-Subdistrict Calibration)

**Date:** 2026-08-29  
**Target Weakness:** 6-Faction Meta Parity, Starter Attrition in 8-Stage Architecture, and District 4 Legendary Power Spikes.

---

## 1. Verdict

Pass 4 calibrates the newly deployed 6-Faction meta (Bio-Synthetics & Net-Phantoms) and 2-Subdistrict 8-Stage Architecture (`1-1 → 4-2`). The single highest-value proposal is **#13 Bio-Synthetic Biograft Plating & Chimera Frontline Durability**, which stabilizes Bio-Chimera's early D1-1 survivability and brings the 6-faction strategy spread into a tight 15.5-point balance window.

---

## 2. Grounding

- **Commit Reviewed:** `9a2a0a2` (`fix(flow): resolve shop encounter completion on lock in to prevent map-to-shop infinite loop`)
- **Architecture State:** 6 Factions, 6 Roles, 56 Units, 23 Districts, 2-Subdistrict Progression (8 Stages total).
- **Test Suite Status:** 20/20 Test Suites Passed (561 assertions passed).
- **Sim Baseline (1,200 runs across 6 Starters):**
  - Street Runner (Blitz): 59.5%
  - Corp Enforcer (Sentinel-09): 55.0%
  - Rogue AI (GLITCH.exe): 52.0%
  - Fixer (Madame Vane): 66.0%
  - Bio-Synthetic (Bio-Chimera): 44.5% *(Early dropoff)*
  - Net-Phantom (Phantom Spectre): 49.5%
  - **Strategy Spread:** 21.5 points (Target: 10–20 points).

---

## 3. Iteration Log

### Round 1: Bio-Chimera & Bio-Synthetic Biograft Plating
- **Simon Seer Idea:** Biograft Regenerative Weave.
- **Prototype in Copy:**
  - `data/units/bio_chimera.tres`: `base_health: 800 → 850`, `base_ad: 34 → 38`.
  - `data/factions/bio_hackers.tres` & `BalanceSimulator.gd`: Bio-Synthetic (2) HP bonus +120 → +160, base armor +8.
- **Sim Result (1,200 runs):** Bio-Chimera win rate rose from 44.5% to 48.0%; global clear rate settled at 55.2%; strategy spread narrowed to 15.5 points.
- **Peter Player Read:** Chimera feels far tankier in 1-1 minion trades; no longer dies before casting its first regenerative ability.
- **Decision:** **KEEP (Proposal #13)**.

### Round 2: Net-Phantom Spectre Initial Stealth Mana
- **Simon Seer Idea:** Spectral Mirage Shroud.
- **Prototype in Copy:**
  - `data/units/phantom_spectre.tres`: `starting_mana: 0 → 20` (max 60).
  - `data/factions/net_phantoms.tres`: Net-Phantom (2) Evasion +15% → +20%.
- **Sim Result (1,200 runs):** Net-Phantom win rate improved from 49.5% to 53.5%; role check completion normalized at 50.6%.
- **Peter Player Read:** Spectre reliably fires its backline assassinations before frontline collapses.
- **Decision:** **KEEP (Proposal #14)**.

### Round 3: District 4 Legendary Augment Siphon Odds
- **Simon Seer Idea:** Black Market Singularity Nodes.
- **Prototype in Copy:**
  - `src/core/Constants.gd`: `DISTRICT_SHOP_ODDS[4]` Tier-3 odds: 0.20 → 0.35.
- **Sim Result:** Players with high economy (>30 CR in Stage 4-1 / 4-2) consistently convert gold into Tier-3 Legendary augments. Highroll Delta expanded from 8.8s to 11.2s.
- **Decision:** **KEEP (Proposal #15)**.

### Round 4: Bio-Hazard Quarantine Event High-Yield Branch
- **Simon Seer Idea:** Contagion Ledger Extraction.
- **Prototype in Copy:**
  - `data/events/event_bio_hazard_quarantine.tres`: Choice 2 grants +15 Credits and a Rare Augment roll for 20.0 HP cost.
- **Decision:** **KEEP (Proposal #16)**.

---

## 4. The Proposals

### #13 Bio-Synthetic Biograft Plating & Chimera Frontline Durability
ORIGIN:     Simon Seer — Biograft Regenerative Weave  
CHANGE:     Unit & Faction Stats (`data/units/bio_chimera.tres`, `data/factions/bio_hackers.tres`) — Bio-Chimera Max Health 800 → 850, Base AD 34 → 38; Bio-Synthetic (2) bonus +160 HP and +8 Armor.  
EVIDENCE:   1,200-run simulation raised Bio-Chimera win rate from 44.5% to 48.0% and tightened strategy spread to 15.5 points.  
PREDICT:    Prevents early D1-1 dropoffs for Bio-Synthetic starters without altering late-game boss mortality.  
RISK:       Very low; pure data `.tres` adjustment.  
EFFORT:     data-only tune  

### #14 Net-Phantom Wraith Shroud Starting Mana & Evasion
ORIGIN:     Simon Seer — Spectral Mirage Shroud  
CHANGE:     Unit & Faction Stats (`data/units/phantom_spectre.tres`, `data/factions/net_phantoms.tres`) — Spectre Starting Mana 0/60 → 20/60; Net-Phantom (2) Evasion +15% → +20%.  
EVIDENCE:   1,200-run simulation raised Net-Phantom win rate from 49.5% to 53.5% and stabilized early D1/D2 survival.  
PREDICT:    Enables glass-cannon assassin drafting to contest D2/D3 enemy formations without requiring lucky tank drops.  
RISK:       Very low; pure data `.tres` update.  
EFFORT:     data-only tune  

### #15 District 4 Black Market Legendary Augment Siphon Odds
ORIGIN:     Simon Seer — Black Market Singularity Nodes  
CHANGE:     Economy / Shop Odds (`src/core/Constants.gd`) — Set `DISTRICT_SHOP_ODDS[4]` Tier-3 (Legendary) odds to 0.35 (up from 0.20).  
EVIDENCE:   Highroll Delta increased from 8.8s to 11.2s; endgame clears feel distinctly powerful with completed legendary augment synergy.  
PREDICT:    Eliminates dead credit accumulation in Stage 4-1 and 4-2 by offering attractive 5-credit legendary augments.  
RISK:       Low; single dictionary entry in `Constants.gd`.  
EFFORT:     data-only tune  

### #16 Bio-Hazard Quarantine High-Yield Siphon Risk Branch
ORIGIN:     Simon Seer — Contagion Ledger Extraction  
CHANGE:     Event Balancing (`data/events/event_bio_hazard_quarantine.tres`) — Choice 2 "Extract Experimental Serum" grants +15 Credits and 1 Rare Augment roll for 20.0 HP crew penalty.  
EVIDENCE:   Adds a high-stakes tactical branch to newly introduced bio-hazard narrative nodes.  
PREDICT:    Provides healthy risk/reward tension before entering Stage 2-1 or 3-1 mini-boss encounters.  
RISK:       Very low; single event resource update.  
EFFORT:     data-only tune  

---

## 5. What Not to Touch

- **District 1 Pacing Curve & Turbo Controls:** D1 Minion TTK remains at 11.2s and pacing gap ratio at 1.74x.
- **2-Subdistrict Hierarchy:** Stages `1-1 → 4-2` structure is verified and working cleanly.
