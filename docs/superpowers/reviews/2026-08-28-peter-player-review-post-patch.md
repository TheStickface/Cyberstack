# Peter Player — Endgame User Review (Post-Escalation & Legendary Patch)

**Date:** 2026-08-28  
**Reviewer:** Peter Player (High-ELO Autobattler Specialist)  
**Target Codebase:** `C:\dev\cyberstack` (v0.1.0-post-escalation)  

---

## 1. Verdict

**YES, I WOULD KEEP PLAYING.** The game transformed from a flat, risk-free stat calculator into a legitimate autobattler with a devastating **9.1-second Highroll Delta**, meaningful boss checks, and instant-restart run flow. When a 3-star Blitz with Singularity Rail ricochets critical hits across an entire boss row while GLITCH.exe pumps +20 mana into the team, the power fantasy finally clicks.

---

## 2. Scorecard (10 Axes)

| # | Axis | Score | Justification / Run Evidence |
|---|---|:---:|---|
| 1 | **Ceiling** | **4 / 5** | Highroll Delta expanded from 0.6s to **9.10s** (P95 TTK 11.2s vs P50 TTK 20.3s on D4 Boss). A god-run deletes the boss in half the time. |
| 2 | **Agency** | **4 / 5** | Smart positioning and augment pairing prevent catastrophic team wipes to the new D4 50% HP boss enrage shockwave. |
| 3 | **Legibility** | **4 / 5** | Live floating combat text now broadcasts `⚡ RICOCHET`, `⚡ +20 MANA`, `🔥 ARMOR MELT -40%`, `☣ -25% ATK SPEED`, and `💥 ENRAGE OVERCLOCK`. |
| 4 | **Power Spikes** | **4 / 5** | D3 (`1.55x HP / 1.30x DMG`) and D4 (`1.95x HP / 1.50x DMG`) scaling require real mid-game spikes; no more sleepwalking through D3. |
| 5 | **Pivotability** | **3 / 5** | Shop tier odds remain relatively uniform; transitioning between factions is viable but shop weightings by district could be sharper. |
| 6 | **Risk / Reward** | **3 / 5** | Econ greed into D2/D3 now carries actual mortality risk if defensive frontline slots are neglected. |
| 7 | **Trap Density** | **3 / 5** | Non-synergized rainbow squads stall out at D4 boss enrage phases without sufficient DPS burst. |
| 8 | **Rarity Payoff** | **5 / 5** | Tier-3 Legendary Augments are now genuine build-defining keystones with transformative behaviors instead of stat bloat. |
| 9 | **Loss Dignity** | **4 / 5** | Boss wipe moments are legible: players see the boss hit 50% HP, trigger `ENRAGE OVERCLOCK`, and cleave the frontline. |
| 10 | **Tempo & Flow** | **4 / 5** | Dead-Run tax abolished via instant "ABANDON RUN" buttons; "QUICK RETRY" and starter carousel on Title Screen eliminate menu friction. |

**Overall Grade:** **3.8 / 5.0** (Up from **2.3 / 5.0** in baseline audit).

---

## 3. Highroll Delta & Ceiling Analysis

- **District 1 Minion Median TTK:** `14.70s`
- **District 4 Boss Median (P50) TTK:** `20.30s`
- **District 4 Boss Highroll (P95) TTK:** `11.20s`
- **Highroll Delta:** **`+9.10s`** (A top 5% build clears the end-game climax **45% faster** than an average build).
- **Combat Pacing Ratio (D1 Minion vs D4 Boss):** `1.38x` (Pacing now properly scales from fast opening encounters to epic multi-phase boss fights).
- **Unique Cleared Compositions:** **865 distinct end-game builds** recorded across 2,000 simulated runs.

---

## 4. Run Tempo & Dead-Run Tax Audit

- **Decided-vs-Ended Gap:** Closed. Players realizing their economy is broken in District 2 or 3 can hit **`✖ ABANDON`** in either the District Map or Prep Screen, banking their accrued meta-reputation immediately.
- **Restart Friction:** Reduced from ~12s / 6 clicks down to **1 click (`↺ QUICK RETRY`)** taking < 1 second.
- **Starter Selection:** 4 distinct starters accessible directly on the Title Screen without navigating deep submenus.

---

## 5. Cross-Run Durability (The "Run 200" Sweep)

- **Starter End-Game Composition Divergence:**
  - `runner_blitz` (Street Runner): 228 distinct winning compositions
  - `corp_sentinel` (Corp Enforcer): 199 distinct winning compositions
  - `ai_glitch` (Rogue AI): 213 distinct winning compositions
  - `fixer_broker` (Fixer): 225 distinct winning compositions
- **Re-Queue Pull:** Strong. The desire to hit double Legendary combos (e.g. *Singularity Rail Ricochet* + *Supernova Armor Melt* on a 3-star sniper) creates genuine highroll chasing.

---

## 6. What to Keep (Do Not Touch)

1. **Legendary Proc Identity:** Singularity ricochet and Neural Hive mana restoration give unmistakable, satisfying tactical feedback.
2. **Boss 50% HP Enrage Phase:** The visual shockwave and stat surge turn boss battles into distinct two-phase encounters.
3. **One-Click Quick Retry Flow:** Instant queueing keeps player momentum high across back-to-back runs.

---

## 7. The Three Ranked Improvement Proposals

### #1: Tiered Shop Odds by District (Dynamic Rarity Rolling)
- **FROM:** Axis 5 (Pivotability) & Axis 1 (Ceiling).
- **CHANGE:** Update `ShopManager.gd` to scale shop offering rarity by District (D1: 100% T1; D2: 70% T1 / 30% T2; D3: 40% T1 / 40% T2 / 20% T3; D4: 20% T1 / 40% T2 / 40% T3).
- **WHY:** Prevents Tier 3 Legendaries from diluting the early D1 shop and makes rolling in District 4 feel like an exciting high-tier jackpot round.
- **PREDICT:** Increases late-game 3-star T2/T3 completion rates from 18% to ~35% while keeping early shop odds tight.
- **EFFORT:** Data/Logic tune in `ShopManager.gd` + `BalanceSimulator.gd`.

### #2: Overdrive Limit Break System (Active Ability Burst Meter)
- **FROM:** Axis 1 (Ceiling) & Axis 2 (Agency).
- **CHANGE:** When a unit casts 3 abilities in a single fight, grant them an "Overdrive" burst state (2x cast speed and guaranteed crit on next spell).
- **WHY:** Gives prolonged boss fights an escalating crescendo that rewards sustained mana-battery builds.
- **PREDICT:** Reduces P95 TTK on highroll mana-loop comps down to ~9.0s.
- **EFFORT:** Sim + Game code in `CombatMockArena.gd` and `BalanceSimulator.gd`.

### #3: District Hazard Combat Modifiers (Tactical Arena Affixes)
- **FROM:** Axis 6 (Risk/Reward) & Cross-Run Durability.
- **CHANGE:** Apply visual and mechanical arena modifiers based on the active district (e.g., Slum Market = "Acid Rain" -10% armor to all; Server Vault = "EMP Pulse" periodic team mana drain).
- **WHY:** Forces players to adjust placement and formation between districts rather than using a static 2x3 layout all run.
- **PREDICT:** Increases Placement Surgeon delta from 0% to ~12% winrate variance based on positioning.
- **EFFORT:** Combat runtime + Sim integration.
