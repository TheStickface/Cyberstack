# Peter Player — Endgame Review: Cyberstack Content & Architecture Expansion

**Reviewer:** Peter Player (Top-500 TFT / Oaken Tower / Autobattler Veteran)  
**Target:** Cyberstack (60 Operatives, 6 Factions, 6 Roles, 20 Augments, 23 Districts)  
**Date:** 2026-08-29  
**Git HEAD:** `73aa398`  

---

## 1. Executive Verdict & The "Run 200" Assessment

> *"Cyberstack with 60 operatives and 6 factions is a fundamentally transformed game from the initial 4-faction proof-of-concept. The build space is vast (576 distinct clear comps, 57 distinct top-decile winning builds), and the highroll ceiling is real (P95 TTK deletes the D4 Boss in 10.2s vs. 19.9s median). But our tempo and combat pacing now have one glaring flaw: early minion fights take 15.7s while the final boss takes 19.9s (a flat 1.27x pacing ratio). We need sharper tempo spikes and higher stakes differentiation between fodder encounters and district climaxes."*

---

## 2. Ten-Axis Scoring Matrix

| # | Axis | Score (1–5) | Status | Assessment & Evidence |
|---|---|---|---|---|
| 1 | **Ceiling** | **4.5 / 5** | **EXCELLENT** | **Highroll Delta = 9.70s.** P95 god-runs (e.g. 3-star Street Ghost with Kinetic Destroyer + Rail) melt District 4 Boss in 10.2s while P50 takes 19.9s. The power ceiling is visceral and rewarding. |
| 2 | **Agency** | **4.0 / 5** | **STRONG** | Decision paths directly determine clear outcomes. Tactical grid adjacency, formation procs (Left/Right/Frontline/Adjacent), and role checks moving event payouts (+32g) reward high-skill execution. |
| 3 | **Legibility** | **4.5 / 5** | **EXCELLENT** | Full tactical tether overlays, live HUD hover tooltips, exact canonical stat lines, and dynamic combat log damage attribution make every synergy and proc instantly readable. |
| 4 | **Power Spikes** | **3.5 / 5** | **ACCEPTABLE** | District 2 (3-slot) and District 3 (4-slot) crew cap unlocks feel great. However, District 1 lacks an immediate "round 1 pivot" moment. |
| 5 | **Pivotability** | **4.5 / 5** | **EXCELLENT** | 6 factions (Street Runners, Corp Enforcers, Rogue AIs, Fixers, Bio-Synthetics, Net-Phantoms) with 60 units mean shop rolling never deadlocks into an unplayable monopoly. |
| 6 | **Risk/Reward** | **3.5 / 5** | **ACCEPTABLE** | Narrative event branches with health costs vs. rare augments offer great gambling lines, but shop rerolling remains mostly low-risk due to high baseline encounter payouts. |
| 7 | **Trap Density** | **4.0 / 5** | **STRONG** | Augment chip tags and canonical stat summaries prevent "trap" items. No item has negative hidden synergy. |
| 8 | **Rarity Payoff** | **4.5 / 5** | **EXCELLENT** | Legendaries (Kinetic Destroyer, Supernova Fusion Core, Neural Hive, Pandemic Strain) fundamentally alter unit behavior and double effective DPS. |
| 9 | **Loss Dignity** | **4.0 / 5** | **STRONG** | Losses are clearly attributable to low star-levels, missing frontline armor against physical burst, or lack of crowd control against high-evasion phantoms. |
| 10 | **Tempo & Pacing** | **2.5 / 5** | **FINDING** | **Pacing Gap Ratio = 1.27x.** D1 trash mobs take 15.7s to resolve while the D4 Boss takes 19.9s. Formality fights consume too much attention relative to their low stakes. |

---

## 3. Highroll Delta & Quantitative Sweep

Across a 1,000-run Monte Carlo sweep:
- **Global Win Rate:** **53.3%**
- **Starter Balance Spread:** **10.8%** (Blitz 53.6%, Sentinel 60.0%, GLITCH 49.2%, Vane 50.4%)
- **D1 Minion Median TTK:** **15.70s**
- **D4 Boss P50 TTK:** **19.90s**
- **D4 Boss P95 TTK:** **10.20s**
- **Highroll Delta:** **9.70s** (P95 vs P50 TTK differential)
- **Top-Decile Winning Build Diversity:** **57 distinct comps** in the top 10% of clears (Zero meta stagnation).
- **Starter Final Comp Divergence:**
  - `runner_blitz`: 146 distinct final compositions
  - `corp_sentinel`: 154 distinct final compositions
  - `ai_glitch`: 133 distinct final compositions
  - `fixer_broker`: 143 distinct final compositions

---

## 4. Key Findings

1. **[TEMPO] Trash Combat Pacing vs. Boss Climax (Score: 2.5/5):**
   - *Problem:* In District 1, 2-unit skirmishes against generic street drones take 15.7 seconds of auto-attacking. In District 4, the climactic Nemesis Synthetic boss encounter takes 19.9 seconds. The player spends 78% as much time watching a trivial opening formality as they do watching the climax of the run.
   - *Fix:* Speed up early minion round pacing or implement combat simulation fast-forward / turbo mode (2x/3x) for non-boss nodes.

2. **[PROGRESSION] Starter Pool Unlock Parity (Score: 3.5/5):**
   - *Problem:* All 6 factions now have thematic starters and level-2 rewards, but meta-progression reputation gain is currently linear.
   - *Fix:* Introduce milestone achievements or distinct starter loadouts per faction upon reaching Level 3.

3. **[POWER FANTASY] Faction Capstone Visual & Stat Punch (Score: 4.0/5):**
   - *Problem:* 6-unit faction bonuses (e.g. Bio-Synthetics 6: +600 HP, +35 Armor, +20% AS; Net-Phantoms 6: +40% Evasion, +35 Speed, +35% Crit, +30 AD) are massive mathematically, but could trigger a distinct battle banner or audio synth surge in combat.

---

## 5. Three Ranked Improvement Proposals

### Proposal 1 (Recommended): Combat Turbo / Auto-Fast-Forward & Encounter Pacing Curve
- **The Pitch:** Fix the 1.27x flat tempo curve by adding a 2x/3x speed toggle in combat and shaving D1 minion HP pools by 25% while scaling encounter damage so early rounds resolve in under 6–8 seconds.
- **Player Impact:** Cuts dead-time on formality fights by over 50%, boosting meaningful decisions per minute from 3.2 to 6.5.

### Proposal 2: High-Stakes Overclock / Greed Shop Mechanics
- **The Pitch:** Introduce "Black Market Overclock" options in the shop: spend 50% of current HP or lock out future rerolls for an immediate guaranteed Tier-3 augment or 4-Cost unit.
- **Player Impact:** Elevates Axis 6 (Risk/Reward) and gives skilled players an aggressive high-risk snowball line.

### Proposal 3: Faction Capstone Ascendancy (6-Piece VFX & Battle Overdrives)
- **The Pitch:** When a player locks in a 6-unit mono-faction comp (Apex Mutation, Phantom Overdrive, Overclock Singularity, etc.), grant that squad a special active Overdrive trigger with custom screen glitch shaders and unique combat surge effects.
- **Player Impact:** Elevates Axis 1 (Ceiling) and Axis 8 (Power Fantasy), giving mono-faction purists an unforgettable god-run payoff.
