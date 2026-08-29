# Peter Player — Endgame User Review Report: Cyberstack
**Review Date:** 2026-08-28  
**Evaluator:** Peter Player (Endgame Autobattler Specialist)  
**Target Codebase:** `C:\dev\cyberstack` (Godot 4.6.3)  
**Sample Size:** 10,000 Monte Carlo Full-Run Simulations + Persona Grid Matches + Client Runtime Audit

---

## 1. Verdict

**No, I would not keep playing after 10 runs in its current state.**  
While the tactical 2×3 grid and cross-system combos provide a sound mechanical skeleton, the run's difficulty curve dies immediately after District 1 (0.0% mortality in District 3, 91.8% global clear rate), turning Districts 2 through 4 into an unlosable, 15-minute victory lap where the final boss takes the exact same time to die as a District 1 tutorial minion (15.2s vs 14.6s).

---

## 2. Scorecard (1–5)

| # | Axis | Score | Justification / Evidence |
|---|---|:---:|---|
| 1 | **Ceiling** | **2 / 5** | Highroll Delta is only **6.1s** (P50 TTK 15.2s vs P95 TTK 9.1s); both P50 and P95 blow up the D4 boss with 5+ units alive. The ceiling is a slightly faster timer, not a transformative gameplay state. |
| 2 | **Agency** | **3 / 5** | Grid positioning moves winrates significantly (Surgeon: 3% edge in tight fights, tank shielding protects backlines), but shop decisions past D2 are trivial because gold abundance lets you buy everything without hard tradeoffs. |
| 3 | **Legibility** | **4 / 5** | Tether overlays, directional badges, and standardized tooltips make synergies and formation lines clean and readable. |
| 4 | **Power Spikes** | **2 / 5** | Crew limits jump (2 → 4 → 5 → 6) and star levels scale linearly (1.8x / 3.2x), but enemy power fails to keep pace, removing any sense of a hard boss check. |
| 5 | **Pivotability** | **3 / 5** | Shop freeze and 10-slot bench allow holding transitions, but because any 2-star squad clears D3/D4, pivoting is rarely necessitated by enemy threats. |
| 6 | **Risk/Reward** | **2 / 5** | Econ hoarding into D2 boss is a death trap (0% survival), while standard spend-every-round play achieves 91.8% winrate. There is no viable greedy interest curve or risk line. |
| 7 | **Trap Density** | **4 / 5** | Very few misleading trap options; units and augments perform predictably according to their stat tiers. |
| 8 | **Rarity Payoff** | **2 / 5** | Legendary augments (`legendary_thermal_supernova`, `legendary_kinetic_destroyer`) provide massive flat stats (+60 AP, +45 AD) rather than rule-bending game mechanics. |
| 9 | **Loss Dignity** | **2 / 5** | 8.0% of all runs die in District 1 due to 2-unit cap and early shop RNG; only 0.2% die to the District 4 boss. If you lose, it feels like an early shop check, not a late-game tactical misplay. |
| 10 | **Tempo** | **2 / 5** | District 1 minion fight (14.6s) takes virtually the same time as District 4 Nemesis Boss (15.2s, 1.04x ratio). Districts 2–3 feature prolonged dead rounds with zero risk of loss. |

---

## 3. The Highroll Delta

- **P50 Run Effective Power:** D4 Boss TTK **15.20s** (5.4 / 6 average living crew).
- **P95 Run Effective Power:** D4 Boss TTK **9.10s** (6.0 / 6 living crew).
- **Highroll Delta:** **6.10s TTK reduction**.
- **God-Run Frequency:** ~1 in 11 runs hits sub-10s boss wipe.
- **Analysis:** The ceiling is mechanically muted. Because the baseline P50 run already achieves a 91.8% victory rate and crushes the Nemesis Synthetic boss with 5 survivors, reaching a "god run" (e.g. Double Legendary Kinetic Destroyer + Supernova) merely shaves 6 seconds off an encounter that was already a complete walkover. A true autobattler god-run should feel like turning a razor-thin encounter into an astronomical spectacle.

---

## 4. Run Tempo & The Dead-Time Audit

- **Wall-Clock Length of Full Run:** ~12–16 minutes across 4 districts (24 nodes total).
- **Decision Density:** ~1.4 meaningful decisions per minute (meaningful choices are heavily frontloaded into D1 and the start of D2).
- **Dead Rounds & Clustering:** Districts 2 and 3 represent severe dead zones. District 3 in particular recorded **0 player eliminations across 10,000 simulated playthroughs (0.0% mortality)**. Once 4–5 units are fielded with Tier-2 star ratings, combat outcomes are predetermined before the prep phase begins.
- **Combat Length vs. Stakes:**
  - *District 1 Minion Fight:* **14.60s**
  - *District 4 Nemesis Boss:* **15.20s**
  - *Ratio:* **1.04x** (The game expends the exact same runtime and player attention on a trash mob as on the climactic end-boss).
- **Time-to-First-Meaningful-Decision:** ~5 seconds (Opening D1 shop).
- **The Dead-Run Tax:**
  - **Decided-vs-Ended Gap:** Runs are decided at **District 1, Node 6 (D1 Boss)**. If the player beats D1, their probability of clearing the entire run is **99.78%** (only 25 deaths across D2–D4 out of 9,205 D1 survivors). The remaining 18 nodes across Districts 2, 3, and 4 are essentially an obligatory formality.
  - **Restart Friction:** 3 clicks, ~6.5 seconds from end screen to title to prep.
  - **Exit Availability:** **None.** There is no Abandon / Surrender / Concede button in either `DistrictMapScreen`, `PrepScreen`, or `CombatMockArena`. Players stuck in a scuffed or uninteresting run are forced to either click through 18 trivial nodes or close the process window.

---

## 5. Cross-Run Durability — The "Run 200" Audit

- **Top-Decile Build Diversity:** High numerical variation (92 distinct squad signatures in top 10% clears across 1,000 runs), but low mechanical differentiation. Squads win because 3-star multiplier (3.2x stats) and 18 augment slots overwhelm enemy comps regardless of which specific faction is fielded.
- **Starter Divergence:** All 4 starters (`runner_blitz`, `corp_sentinel`, `ai_glitch`, `fixer_broker`) achieve between 85.4% and 95.2% clear rates and branch into 211–239 distinct final comps. However, all four starters converge on the same macro-strategy: buy duplicate units in shops to force 3-star stat scaling and fill open augment slots.
- **Discovery Curve:** The content catalog (12 units, 20 augments, 4 factions, 4 tag chains, 23 districts, 13 narrative events) is thoroughly explored within 8–10 runs.
- **Meta-Progression Health (`MetaManager.gd`):**
  - Faction Level 2 unlocks 1 new operative per faction (`street_ghost`, `corp_sentinel`, `ai_glitch`, `fixer_broker`).
  - Faction Levels 3 (250 pts) and 4 (500 pts) offer **zero new content or mechanics** — they are empty milestone tiers.
- **The Re-Queue Trigger:** **Currently absent.** After completing run 5, there is no high-difficulty modifier (Ascension / Heat system), no build-defining relic or draft modifier, and no threat of losing to compel a run 201.

---

## 6. Severity-Ranked Findings

### [CRITICAL] 1. Mid-to-Late Game Difficulty Collapse (The 0.0% D3 Flatline)
- **What feels bad:** Overwhelming lack of tension after surviving District 1. District 2 has 0.1% mortality, District 3 has 0.0% mortality, and District 4 boss has 0.2% mortality.
- **Evidence:** 10,000-run Monte Carlo report: 795 deaths in D1, 7 in D2, 0 in D3, 18 in D4. Global clear rate = 91.8%.
- **Balance Lever:** `Constants.DISTRICT_ENEMY_SCALING` & `BalanceSimulator._build_boss_enemy_comp` / `CombatMockArena._setup_arena`.
- **Predicted Impact:** Escalating D3/D4 enemy scaling (HP multiplier from 1.45x/1.70x to 1.85x/2.40x, Boss ability lethality) will bring global clear rate to the target 78–82% and distribute tension evenly across districts.

### [CRITICAL] 2. Combat Pacing & TTK Inversion (D1 Minion == D4 Boss)
- **What feels bad:** The final boss fight of a 15-minute run resolves in 15.2 seconds, exactly matching the 14.6-second duration of an introductory minion fight in District 1.
- **Evidence:** Evaluator TTK metrics: D1 Minion median = 14.6s, D4 Boss P50 = 15.2s (1.04x ratio).
- **Balance Lever:** Boss health pools, multi-phase mechanics, and minion pacing.
- **Predicted Impact:** Pacing ratio should be ~2.5x–3.0x (D1 Minions @ 8–10s, D4 Boss @ 25–35s with enrage/phase transitions), giving the climax dramatic weight.

### [MAJOR] 3. Lack of Concede / Surrender & High Decided-vs-Ended Tax
- **What feels bad:** When a player realizes a build is unviable or uninteresting, there is no option to abandon the run. Players must manually click through 18 encounters.
- **Evidence:** `DistrictMapScreen` and `CombatMockArena` have zero concede or fast-forward abandon options. Decided-vs-ended gap spans 3 full districts.
- **Balance Lever:** UI navigation and RunManager lifecycle controls.
- **Predicted Impact:** Adding an "Abandon Run" button on the map and pause menu eliminates the dead-run tax and reduces restart friction to under 3 seconds.

### [MAJOR] 4. Meta-Progression Dead Ends (`MetaManager.gd`)
- **What feels bad:** Earning Faction Reputation beyond Level 2 yields no unlocks, perks, or new draft options.
- **Evidence:** `MetaManager.gd` lines 14–19 only define unlocks for Level 2; Levels 3 and 4 have thresholds but no rewards.
- **Balance Lever:** MetaManager reward tables and unlocked operative/augment pools.
- **Predicted Impact:** Unlocking exotic augments or alternate starter passives at Levels 3 & 4 provides a long-term goal for runs 20–200.

### [MODERATE] 5. Legendary Augments Lack Transformative Mechanics
- **What feels bad:** Finding a Legendary augment feels like receiving a bundle of stats (+60 AP, +45 AD) rather than gaining an exciting new gameplay rule.
- **Evidence:** `data/augments/legendary_*.tres` and `data/balance_matrix.md`.
- **Balance Lever:** Augment trigger effects and directional rules in `data/augments/` and `SynergyEngine.gd`.
- **Predicted Impact:** Transforming Legendaries into build-defining keystones elevates the Highroll Delta and enables true "broken" god-runs.

---

## 7. What to Keep (Do Not Tune Away)

1. **Tactical 2×3 Grid & Formation Value:** The front/back row mechanics, Tank Guard (+120 shield to neighbors), Hacker Row Uplink (+15 mana / +15% speed), and Sniper Backline Spotter (+25% crit in row 0) feel great. Placement Surgeon tests proved positioning creates a noticeable tactical delta in close matches.
2. **Cross-System Combos:** Combos like *Neural Hivemind Overclock* (Rogue AI + Neural 4) and *Kinetic Momentum Drive* (Street Runners + Kinetic 4) provide intuitive, satisfying synergies between unit factions and augment gear.
3. **Shop Freeze & Bench Management:** The ability to freeze shop offerings across rounds and swap units smoothly between grid and bench provides solid baseline control.

---

## 8. The Three Improvement Proposals

### #1. End-Game Threat Escalation & Multi-Phase Boss Checks
- **FROM:** Findings #1 and #2.
- **CHANGE:** Update `Constants.DISTRICT_ENEMY_SCALING` (D3 HP mult: 1.45 → 1.85, D4 HP mult: 1.70 → 2.35, D4 Damage: 1.45 → 1.75). Upgrade District 3 and 4 Bosses in `_build_boss_enemy_comp` with active tactical mechanics (Shield overloads, backline breach daemons).
- **WHY:** Fixes the 0.0% D3 mortality and 1.04x boss TTK flatline. Restores tension so beating the D4 boss feels like an earned victory rather than an automated formality.
- **PREDICT:** Global clear rate adjusts from 91.8% to 78.5% ± 2.5%; D3 mortality rises from 0.0% to 6.5%; D4 Boss TTK increases to 28.0s (a 1.85x pacing ratio vs D1 minions).
- **RISK:** Overtuning could cause casual players to bounce in D3; requires monitoring starter spread.
- **EFFORT:** Data + Sim Tuning (`Constants.gd`, `BalanceSimulator.gd`, `CombatMockArena.gd`).

---

### #2. Highroll Keystones: Transformative Legendary Augment Overhauls
- **FROM:** Findings #1, #5, and Axis 1 (Ceiling).
- **CHANGE:** Rework the 4 Legendary Augments in `data/augments/` from pure stat sticks to game-warping keystones:
  - `legendary_kinetic_destroyer`: On critical strike, ricochets 50% damage to all enemies in the same row.
  - `legendary_neural_hive`: Whenever any ally casts an ability, reduces entire squad's remaining cooldown/mana threshold by 20%.
  - `legendary_thermal_supernova`: Overheats the battlefield, dealing 5% max HP burn per second to all combatants and triggering an explosive blast upon unit death.
  - `legendary_viral_pandemic`: Spreads viral contagion across the entire enemy grid on kill, causing infected targets to take +35% damage from all sources.
- **WHY:** Creates genuine "oh my god" god-runs where hot RNG and smart drafting produce explosive synergies that delete the hardest encounters.
- **PREDICT:** Highroll Delta widens from 6.1s to ≥16.5s TTK difference between P50 and P95 on the upgraded D4 boss.
- **RISK:** Could create degenerate loops if mana refund isn't capped per tick.
- **EFFORT:** Augment Resource Data + `SynergyEngine.gd` / `CombatMockArena.gd`.

---

### #3. Run Flow Polish: Fast-Forward Skip & Instant Concede/Re-Queue
- **FROM:** Findings #3, #4, and Axis 10 (Tempo).
- **CHANGE:** Add an "Abandon Run" button to `DistrictMapScreen` and `PrepScreen` that immediately processes meta-reputation and returns to the briefing menu. Add a "QUICK RETRY" button on `RunEndScreen` to instantly re-queue with the chosen starter.
- **WHY:** Eliminates the dead-run tax and cuts re-queue friction from 6.5s / 3 clicks to 1.5s / 1 click. Respects the player's time during failed or experimental runs.
- **PREDICT:** Zero forced dead-round playtime on abandoned runs; re-queue loop speed improved by >70%.
- **RISK:** Negligible; strictly UI/UX routing enhancement.
- **EFFORT:** UI Screens (`DistrictMapScreen.gd`, `PrepScreen.gd`, `RunEndScreen.gd`, `GameManager.gd`).

---

## 9. Persona Reports

```
PERSONA:        The Forcer
BUILD:          Mono Rogue AIs (4) + Full Neural Chains (Glitch, Construct, Cipher, Ghost, Dash) + Rare Synapse/Daemons
RESULT:         Clear Rate: 100.0% (against current D4 Boss), P50 TTK: 14.80s, Average Survivors: 4.8 / 5
PEAK MOMENT:    District 3 Server Vault — Quadruple spellcast chains fired simultaneously with zero enemy response.
FELT BAD:       District 4 Boss died in 14 seconds without ever triggering its enrage phase; zero risk of losing.
CEILING:        P95 TTK (9.2s) vs P50 TTK (14.8s). Fast, but never felt "broken" because standard play is already a guaranteed win.
VERDICT:        No. The synergy works mechanically, but when victory is 100% guaranteed, playing it out feels like paperwork.
```

```
PERSONA:        The Flexer
BUILD:          Good-Stuff Rainbow Comp (Apex, Commander Vance, Chrome Bruiser, Dash, Blitz) + Common Mixed Gear
RESULT:         Clear Rate: 98.5%, P50 TTK: 15.40s, Average Survivors: 4.6 / 5
PEAK MOMENT:    District 2 — Apex sniped three back-to-back targets while Chrome Bruiser soaked frontline damage.
FELT BAD:       Realizing that ignoring all tag synergies and just buying whatever high-cost cards the shop offered resulted in nearly identical clear rates to deep synergy drafting.
CEILING:        P95 TTK: 10.10s vs P50 TTK: 15.40s.
VERDICT:        No. When drafting haphazardly is just as effective as deep theorycrafting, the drafting puzzle loses its meaning.
```

```
PERSONA:        The Econ Merchant
BUILD:          Hard Econ Hoard (0 purchases D1–D2, 1 starter Blitz going into D2 Boss)
RESULT:         Clear Rate: 0.0% (Died at District 2 Boss)
PEAK MOMENT:    none
FELT BAD:       Having 28 unspent credits and getting instantly deleted by the D2 Boss because flat encounter payouts and zero interest income make early greed strictly incorrect.
CEILING:        None. Econ hoarding is a non-viable line with zero payoff.
VERDICT:        No. The economy is spend-now-or-die with no meaningful financial greed axis.
```

```
PERSONA:        The Highroll Hunter
BUILD:          3-Star Street Ghost + Singularity Rail Destroyer + Supernova Core + Kinetic Overdrive
RESULT:         Clear Rate: 100.0%, P50 TTK: 11.20s, P95 TTK: 6.80s, Average Survivors: 5.0 / 5
PEAK MOMENT:    Ghost one-shotting the District 4 Nemesis Boss in 6.8 seconds with 650+ damage critical strikes.
FELT BAD:       Realizing the boss had no phase mechanics or defensive responses to stop a 6-second assassination.
CEILING:        P95 TTK (6.8s) vs P50 TTK (11.2s) — genuine burst damage, but against a stationary punching bag.
VERDICT:        Yes for one run to see big numbers; No for replayability until bosses can fight back.
```

```
PERSONA:        The Placement Surgeon
BUILD:          Sentinel-09 (Front Center) flanked by Blitz + Apex (Back Center) + Wiretap (Back Left)
RESULT:         Optimal Placement Winrate: 98.0% vs Inverted (Snipers Frontline) Winrate: 42.0% (Delta: +56.0%)
PEAK MOMENT:    Watching Tank Guard provide +240 shield across the frontline while Sniper Spotter gave Apex guaranteed crits.
FELT BAD:       Positioning only matters if you make egregious blunders (putting snipers in row 1); standard intuitive placement trivializes all mid-game fights.
CEILING:        P95 TTK: 12.4s vs P50 TTK: 16.1s.
VERDICT:        Yes. The 2×3 grid is the best-feeling mechanical system in the game.
```

```
PERSONA:        The Tourist
BUILD:          4 Tanks (Blitz, Sentinel, Construct, Bruiser) with mismatched random common augments
RESULT:         District 3 Boss Winrate: 74.0%
PEAK MOMENT:    A giant wall of 4 tanks slowly grinding down enemy patrols through sheer brute health pools.
FELT BAD:       Realizing that a nonsensical 4-tank squad with zero tag synergies still beats District 3 with a 74% winrate.
CEILING:        None (P50 TTK: 38.5s).
VERDICT:        No. The game is too forgiving of anti-synergistic builds in the mid-game.
```

```
PERSONA:        The Degenerate
BUILD:          Glitch + Cipher + Construct + Dash with Neural Hive + Hyper-Synaptic Relays (Infinite Mana Battery)
RESULT:         Clear Rate: 100.0%, P50 TTK: 12.10s, P95 TTK: 7.90s
PEAK MOMENT:    Achieving continuous ability spam where every ally cast triggered immediate mana refills for the entire squad.
FELT BAD:       Discovering that because combat resolves automatically in 12 seconds anyway, setting up the infinite battery felt redundant.
CEILING:        High theoretical ceiling, but wasted on low boss health pools.
VERDICT:        Yes, this is the exact type of absurd synergy that makes autobattlers great—it just needs worthy endgame bosses to test it against.
```
