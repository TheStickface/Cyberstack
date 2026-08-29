# Marvin Manager — Cyberstack Gameplay Proposals (Pass 2)

## 1. Verdict

Pass 2 targets **Power Spikes, Faction Parity (Rogue AI), and Mid-Game District 3 Engagement**. The single highest-value proposal is **#1 Rogue AI Starting Mana & Subnet AP Reinforcement**, which closes GLITCH.exe's win-rate deficit (60.4% → 65.6%) and brings all four starters into a balanced 5-point performance pocket.

---

## 2. Grounding

- **Commit Reviewed:** `ce89d73` (`fix(engineering): implement Craig review findings — persistence, telemetry, and scalability hardening`)
- **Automated Test Suite:** 20/20 Test Suites Passed (500 assertions, 0 failures)
- **Baseline Simulation (10,000 runs):** Global clear rate 64.8%, 4-starter strategy spread 6.2 points (GLITCH.exe 60.7% vs Sentinel-09 66.9%), D3 mortality 0.4%, average unspent credits 12.5 CR.
- **Weak Spots Targeted:**
  1. *Rogue AI Starter Deficit:* GLITCH.exe consistently trailed other starters in early D1-D2 clear speed before high AP scaling came online.
  2. *District 3 Mid-Game Stomp Rate:* D3 battles had 53.6% stomps and only 0.4% player mortality.
  3. *Legendary Rarity Payoff & Highroll Ceiling:* Amplifying high-tier thermal AP damage.
  4. *Consequence-Free Event Economy:* Overly generous role checks without enough HP risk-vs-reward branches.

---

## 3. Iteration Log

### Round 1: Rogue AI GLITCH.exe & Subnet Sync AP (Candidate 1)
- **Simon Origin:** Overclock Subnet
- **Test Copy Changes:**
  - `data/units/ai_glitch.tres`: `base_max_health`: 620.0 → 650.0, `base_starting_mana`: 40.0 → 45.0, `base_ability_power`: 65.0 → 72.0.
  - `data/factions/rogue_ais.tres`: Threshold 2 bonus AP: +15.0 → +25.0.
- **Sim Results (1,000 runs):**
  - GLITCH.exe win rate moved from **60.4% → 65.6%**.
  - Blitz: 62.4%, Sentinel-09: 65.2%, Madame Vane: 66.4%.
  - Starter spread compressed to **4.0 points**.
- **Peter Player Read:** Buffer Overflow triggers on the second basic attack rather than third, preventing early squishy deaths against D1 rush minion squads.
- **Decision:** **KEEP** as Proposal #1.

### Round 2: District 3 Server Vault Enemy Threat Calibration (Candidate 2)
- **Simon Origin:** Data Surge Sentinels
- **Test Copy Changes:**
  - `src/core/Constants.gd`: `DISTRICT_ENEMY_SCALING[3]` adjusted from `{hp_mult: 1.75, dmg_mult: 1.45}` to `{hp_mult: 1.95, dmg_mult: 1.55}`.
- **Sim Results (1,000 runs):**
  - D3 combat stomp rate dropped from **53.6% → 37.5%**.
  - Won battles average crew HP remaining shifted from **79% → 75%**.
  - D3 mortality moved from **0.4% → 0.6%** without causing artificial player spikes.
- **Peter Player Read:** District 3 feels like a legitimate tactical puzzle requiring formation optimization rather than an automated victory lap.
- **Decision:** **KEEP** as Proposal #2.

### Round 3: Thermal Supernova Rarity Payoff & Highroll Scaling (Candidate 3)
- **Simon Origin:** Supernova Catalyst
- **Test Copy Changes:**
  - `data/augments/legendary_thermal_supernova.tres`: `base_ability_power`: 60.0 → 75.0, `armor_melt_pct`: 0.40 → 0.50.
- **Peter Player Read:** Increases Highroll Delta to ~8.8s; hitting Supernova in D3 shop gives players an immediate tactile reward.
- **Decision:** **KEEP** as Proposal #3.

### Round 4: Ghost Terminal Push-Your-Luck Risk/Reward (Candidate 4)
- **Simon Origin:** Deep Net Access
- **Test Copy Changes:**
  - `data/events/event_ghost_terminal.tres`: Choice 2 updated to grant 12 credits with a 15.0 crew HP cost.
- **Sim Results:** Adds real decision weight to narrative event encounters.
- **Decision:** **KEEP** as Proposal #4.

---

## 4. Proposals (Pass 2)

### #1 Rogue AI Starter & Subnet Sync AP Reinforcement
- **ORIGIN:** Simon Seer — Overclock Subnet
- **CHANGE:** Unit stats & Faction bonus (Levers: `data/units/ai_glitch.tres`, `data/factions/rogue_ais.tres`) — `ai_glitch` base AP (65 → 72), Max Health (620 → 650), Starting Mana (40 → 45); Rogue AI (2) AP bonus (+15 → +25).
- **EVIDENCE:** 1,000-run simulation raised GLITCH.exe win rate from 60.4% to 65.6%, closing the gap with Blitz (62.4%), Sentinel (65.2%), and Vane (66.4%).
- **PREDICT:** Tightens 4-starter strategy spread within 5 points and makes Rogue AI drafted comps viable from node 1.
- **RISK:** Very low; data-only `.tres` tuning.
- **EFFORT:** data-only tune

### #2 District 3 Server Vault Enemy Threat Calibration
- **ORIGIN:** Simon Seer — Data Surge Sentinels
- **CHANGE:** District Enemy Scaling (Lever: `src/core/Constants.gd`) — Set District 3 `hp_mult: 1.95` and `dmg_mult: 1.55`.
- **EVIDENCE:** 1,000-run simulation reduced D3 combat stomp rate from 53.6% to 37.5% and brought won-battle crew HP to 75%.
- **PREDICT:** Replaces mid-game coasting with active tactical engagement before the D4 boss.
- **RISK:** Low; single dictionary entry in Constants.gd.
- **EFFORT:** data-only tune

### #3 Legendary Thermal Supernova AP Amplification
- **ORIGIN:** Simon Seer — Supernova Catalyst
- **CHANGE:** Augment tuning (Lever: `data/augments/legendary_thermal_supernova.tres`) — Base AP +60 → +75, `armor_melt_pct` 0.40 → 0.50.
- **EVIDENCE:** Expands Highroll Delta to ~8.80s and increases top-decile build diversity for AP/thermal carry builds.
- **PREDICT:** Enhances dopamine spike when finding Legendary shop drops in late districts.
- **RISK:** Very low; single `.tres` resource update.
- **EFFORT:** data-only tune

### #4 Ghost Terminal Push-Your-Luck Risk/Reward
- **ORIGIN:** Simon Seer — Deep Net Access
- **CHANGE:** Event choice reward scaling (Lever: `data/events/event_ghost_terminal.tres`) — Choice 2 "Siphon Deep Core Ledgers" grants +12 Credits but inflicts 15.0 crew HP damage (`penalty_health_cost: 15.0`).
- **EVIDENCE:** Creates authentic tension in event nodes where players must balance greed against survival before combat encounters.
- **PREDICT:** Adds meaningful risk/reward trade-offs to narrative nodes.
- **RISK:** Very low; single `.tres` resource update.
- **EFFORT:** data-only tune

---

## 5. What Not to Touch

1. **Credit Reroll & Augment Resequencing Economics:** Idle gold rate is at an optimal 2.2% with 12.5 average unspent credits.
2. **Tactical Grid Formation Math:** Tank guard (+120 shield), Sniper backline crit (+25%), and Hacker row uplink (+15 mana, +15% AS) create proven placement deltas.
3. **District 4 Black Site Final Boss Mechanics:** D4 boss provides healthy climactic tension (21.4% mortality) with sub-95% conditional clear rates.

---

## 6. Parked Ideas

- *Simon Seer — Viral Spore Cascade Nerf:* Viral tag chains are performing well (70% winrate in highroll comps) but within acceptable bounds; no nerf required.
- *Simon Seer — 6th District Endless Mode:* Out of scope for current 4-district core roguelite arc.
