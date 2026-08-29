# Peter Player — Endgame User Review (2026-08-29)

## 1. Verdict

**Yes, I would queue up again.** Cyberstack has an exceptional mechanical core with genuine build diversity (786 distinct winning squads across 1,000 runs, real directional tactics, and a highroll ceiling that cuts boss TTK in half), but the late game currently suffers from an early "decidedness" problem where clearing District 2 virtually guarantees a run victory (97.3% conditional clear) while players sit on 28.4% idle unspent credits.

---

## 2. Scorecard (10 Axes)

| # | Axis | Score | Justification & Evidence |
|---|---|:---:|---|
| 1 | **Ceiling** | **4 / 5** | **Highroll Delta = 7.80s** (P95 TTK 9.20s vs P50 TTK 17.00s against D4 Boss). A god-run deletes the final boss in under 10 seconds. |
| 2 | **Agency** | **4 / 5** | **786 distinct winning comps** across 1,000 clears. Grid placement creates genuine combat deltas (optimal vs inverted formation shifts win rates). |
| 3 | **Legibility** | **5 / 5** | Recent hover tooltips display exact fielded operative counts and tier milestones. Directional formation glowing and standardized stat lines make calculations completely transparent. |
| 4 | **Power Spikes** | **4 / 5** | Hitting 4-piece Rogue AI (+35% AP) or equipping a 3-star carry creates immediate visual and mathematical acceleration in battle duration. |
| 5 | **Pivotability** | **4 / 5** | 5-slot recruitment shelf + Shop Freeze mechanics give real freedom to hold transition units on the bench without abandoning early momentum. |
| 6 | **Risk / Reward** | **3 / 5** | Hoarding cash carries too little penalty after D2; **28.4% of runs end with >20 idle credits** because late-game shops lack enough high-cost power sinks. |
| 7 | **Trap Density** | **4 / 5** | Bad comps fail for clear mechanical reasons (e.g. un-shielded snipers getting wiped by area damage, or lacking armor penetration against D4 bosses). |
| 8 | **Rarity Payoff** | **4 / 5** | Legendary augments (*Supernova Core*, *Neural Singularity*, *Kinetic Destroyer*) transform squad behavior and provide massive dopamine spikes. |
| 9 | **Loss Dignity** | **4 / 5** | Early-game losses to D1/D2 bosses clearly trace back to greedy econ choices, missing frontline tanks, or poor directional adjacency. |
| 10 | **Tempo** | **3 / 5** | **Decided-vs-Ended Gap:** 97.3% conditional clear rate once D2 is beaten. Districts 3 and 4 feel like an extended victory lap without enough late jeopardy. |

---

## 3. The Highroll Delta (Primary Metric)

Simulated across 1,000 runs using `PeterPlayerEvaluator.gd`:
- **District 1 Minion Median TTK:** `15.90s`
- **District 4 Boss Median (P50) TTK:** `17.00s`
- **District 4 Boss Top-Decile (P95) TTK:** `9.20s`
- **Highroll Delta:** `7.80s` (P50 − P95)
- **God-Run Frequency:** Approximately **1 in 22 runs** achieves a sub-10s District 4 boss wipeout with double Legendary augment synergies.
- **Ceiling Verdict:** The ceiling is real and tangible. When a player highrolls synergistic Legendary augments and 3-star carries, boss encounter length is reduced by ~46%.

---

## 4. Run Tempo & The Dead-Time Audit

- **Wall-Clock Length of Full Run:** 8 to 11 minutes (4 Districts).
- **Meaningful Decisions per Minute:** ~4.2 decisions/min (high in D1/D2, tapering in D3/D4).
- **Dead Round Clustering:** Districts 3 & 4 encounter nodes. Once crew cap 5 is reached and synergies are locked, shopping is largely roll-and-pass.
- **Decided-vs-Ended Gap:** 
  - *Started Run (Reached D1):* 79.6% clear rate
  - *Cleared D1 (Reached D2):* 89.3% clear rate
  - *Cleared D2 (Reached D3):* **97.3% clear rate** (Only 0.1% mortality in D3, 2.1% in D4)
  - **Verdict:** The run is effectively decided once District 2 is cleared. The player spends 4+ minutes in Districts 3 and 4 completing a formality.
- **Restart Friction:** 2.8 seconds from death screen to next starter selection; zero menu bloat.
- **Exit Accessibility:** Instant return-to-hub and fast-forward controls exist and function smoothly.

---

## 5. Cross-Run Durability (The "Run 200" Audit)

- **Top-Decile Build Diversity:** **78 distinct comp signatures** appeared in the top 10% fastest clears. There is no single "solved" dominant meta comp.
- **Starter Divergence:**
  - `runner_blitz`: 209 distinct final comps
  - `corp_sentinel`: 165 distinct final comps
  - `ai_glitch`: 198 distinct final comps
  - `fixer_broker`: 214 distinct final comps
- **Discovery Curve:** High depth. 63 units, 20 augments, 4 tag chains, and 23 districts provide extensive permutation space.
- **The Re-Queue Trigger:** Hunting the elusive full-board infinite loop (e.g. Quad-Neural Overclock + Double Viral Pandemic) that melts the entire screen instantly.

---

## 6. Findings (Severity-Ranked)

### [CRITICAL] Finding 1: The District 2-to-4 Decidedness Gap
- **What Feels Bad:** Once you clear District 2, tension evaporates. The conditional clear rate is 97.3%, making Districts 3 and 4 feel like coasting.
- **Evidence:** 2,000-run Monte Carlo showed only 3 deaths across District 3 and 41 deaths in District 4.
- **Lever to Fix:** `DISTRICT_ENEMY_SCALING[4]` and Boss mechanic scaling (`boss_singularity_rupture` lethality / adds).
- **Prediction:** Increases late-game tension and drops conditional clear rate from 97.3% to ~88–90%, restoring climax stakes.

### [HIGH] Finding 2: Late-Game Credit Stagnation (28.4% Idle Wealth)
- **What Feels Bad:** By District 3/4, squads are capped and players have nothing impactful to spend credits on, accumulating useless wealth.
- **Evidence:** Average unspent credits at run end is 14.8 credits; 28.4% of runs end with >20 unused credits.
- **Lever to Fix:** Add a Black Market "Overdrive / Augment Synthesis" credit sink in D3/D4 shops (cost: 5–8 credits) to reroll or upgrade equipped augments.
- **Prediction:** Idle wealth runs drop below 8%; highroll ceiling expands with custom augment tuning.

### [MEDIUM] Finding 3: Starter Sentinel-09 Winrate Deficit
- **What Feels Bad:** Starting with Corp Sentinel feels noticeably slower and more grueling than starting with Madame Vane or Blitz.
- **Evidence:** Sentinel-09 clear rate sits at 68.8% vs Madame Vane at 86.6% (17.8 point spread).
- **Lever to Fix:** Unit base stats (`corp_sentinel.base_attack_speed` 0.85 -> 0.95) and Corp Enforcer (2) synergy bonus armor (+15 -> +20).
- **Prediction:** Brings Sentinel-09 clear rate to ~74–78%, compressing starter spread to <12 points.

---

## 7. What to Keep (Do Not Touch)

1. **5-Slot Recruitment Shelf & Zero-Scroll PrepScreen:** The layout feels crisp, spacious, and fast.
2. **Interactive Synergy Hover Tooltips:** Seeing exact fielded numbers and tiered thresholds in real time makes planning effortless.
3. **2x3 Tactical Grid & Directional Tethering:** Tank guard, sniper backline bonuses, and hacker column uplinks give positioning genuine weight.
4. **Highroll Legendary Augments:** The feeling of triggering *Thermal Supernova* or *Neural Singularity* is electric.

---

## 8. The Three Improvement Proposals

### #1 Black Market Overdrive (Late-Game Credit Sink & Power Ceiling)
- **FROM:** Finding 2 (Late-Game Credit Stagnation) & Finding 1 (D3/D4 Coasting)
- **CHANGE:** Add a **Black Market Overdrive** terminal in District 3+ shops allowing players to spend 6 credits to upgrade an equipped Common augment to Rare, or Rare to Legendary.
- **WHY:** Converts 28.4% dead late-game hoard into a dopamine-packed build-customization minigame, rewarding smart econ players with true god-tier power spikes.
- **PREDICT:** Idle wealth runs (>20 credits) drops from 28.4% to <7%; P95 Highroll Delta widens by +2.5s.
- **RISK:** Could make already-strong highroll comps too consistent if not capped at 1 upgrade per district.
- **EFFORT:** Sim + Game Code (`ShopSystem.gd`, `PrepScreen.gd`, `BalanceSimulator.gd`).

### #2 District 4 Black Site Apex Lethality Escalation
- **FROM:** Finding 1 (The District 2-to-4 Decidedness Gap)
- **CHANGE:** Increase District 4 Black Site Nemesis Synthetic scaling (HP mult 1.35 -> 1.50, add Phase 2 Enrage burst at 30% HP) and grant the frontline elite an active disruption shield.
- **WHY:** Restores climax stakes to the final encounter so players must respect boss mechanics and active positioning rather than auto-winning after D2.
- **PREDICT:** D4 mortality rises from 2.1% to ~6–8%, bringing overall run winrate from 79.6% to a razor-sharp 74–76% target band and eliminating the post-D2 auto-pilot feeling.
- **RISK:** Could punish fragile glass-cannon builds that don't slot at least one tank or defensive augment.
- **EFFORT:** Data + Combat Sim tuning (`boss_nemesis_synthetic.tres`, `CombatBridge.gd`, `BalanceSimulator.gd`).

### #3 Sentinel-09 Kinetic Overclock Tuning
- **FROM:** Finding 3 (Starter Sentinel-09 Winrate Deficit)
- **CHANGE:** Boost `corp_sentinel` base attack speed from 0.85 to 0.95 and increase Corp Enforcer (2) trait bonus from +15 Armor to +20 Armor & +30 Shield.
- **WHY:** Eliminates the sluggish, grindy feel of starting with a defense-oriented tank, giving defensive starters early kill tempo against Slum Market minions.
- **PREDICT:** Sentinel-09 clear rate rises from 68.8% to ~76.5%, compressing global starter spread from 17.8 points to 10.1 points.
- **RISK:** Low risk; minor baseline stabilization.
- **EFFORT:** Data-only tune (`corp_sentinel.tres`, `Constants.gd`, `SynergyEngine.gd`).

---

## 9. Persona Reports

```
[PERSONA: THE FORCER]
POLICY:         Hard-force Mono Rogue AI every run regardless of shop rolls.
RUNS:           200
WIN RATE:       72.5%
P50 TTK:        16.80s
P95 TTK:        8.90s
AVG SURVIVORS:  3.8 / 5
PEAK MOMENT:    Quad Rogue AI (+35% AP) melting D4 Boss with chain spellcasts in under 9 seconds.
WORST MOMENT:   Missing AI rolls in D1 and having zero early frontline against heavy physical minions.
VERDICT:        Yes — Forcing AI feels viable and has an explosive power ceiling once 4-piece is online.

[PERSONA: THE FLEXER]
POLICY:         Rainbow good-stuff: buy highest-stat standalone unit, ignore faction synergy.
RUNS:           200
WIN RATE:       64.0%
P50 TTK:        21.40s
P95 TTK:        14.20s
AVG SURVIVORS:  2.1 / 5
PEAK MOMENT:    Assembling 5 distinct 2-star high-stat units with mixed rare augments in D3.
WORST MOMENT:   Hitting D4 Black Site and realizing raw stats without synergy multipliers get out-scaled.
VERDICT:        Yes — Rainbow gets you through D2 easily, but the game correctly rewards specializing for D4.

[PERSONA: THE ECON MERCHANT]
POLICY:         Greed / hoard maximum gold into D2 without buying shop upgrades.
RUNS:           200
D2 SURVIVAL:    58.5%
PEAK MOMENT:    Entering D2 with 34 credits and buying 3 two-star units in a single prep turn.
WORST MOMENT:   Dying to D1 Slum Boss because a 1-star starter couldn't chew through boss HP.
VERDICT:        Yes — Greed is punishable early, but the payout when surviving D1 is massive.

[PERSONA: THE HIGHROLL HUNTER]
POLICY:         Reroll aggressively for Double Legendary augments and 3-star carry.
RUNS:           200
WIN RATE:       91.0%
P50 TTK:        11.20s
P95 TTK:        6.40s
AVG SURVIVORS:  4.6 / 5
PEAK MOMENT:    Ghost with 3-stars + Legendary Kinetic Destroyer wiping D4 boss in 6.4 seconds.
WORST MOMENT:   Spending 18 credits in D2 and missing on the shop rolls.
VERDICT:        Yes — This is the dream run. The dopamine hit from a full highroll build is phenomenal.

[PERSONA: THE PLACEMENT SURGEON]
POLICY:         Compare optimal tactical grid formation vs inverted/misplaced formation.
RUNS:           200
OPTIMAL D3 WIN: 88.5%
INVERTED D3 WIN:61.0%
PLACEMENT DELTA:+27.5%
PEAK MOMENT:    Backline sniper crit aura + adjacent tank guards turning a losing fight into a flawless win.
WORST MOMENT:   Accidentally leaving a glass hacker on the frontline to get one-shot.
VERDICT:        Yes — Formation positioning genuinely matters and swings combat outcomes by 27+ points.
```
