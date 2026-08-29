# Peter Player Endgame User Review

**Date:** 2026-08-29  
**Reviewer:** Peter Player (Top-500 Autobattler Veteran)  
**Target Commit:** `cc9234b` (`feat(proposals): implement Pass 4 & Pass 5 proposals #15-#20`)  
**Scope:** Full-run feel, 6-Faction Meta, 3-Crew Opening Frontline, Tactical Grid Adjacencies, Run Tempo, and Power Ceiling.

---

## 1. Verdict

**Would I keep playing? YES.**  
The 3-unit opening frontline and Commander adjacency aura turned the tactical grid into a real game from Round 1, and the 6-faction pool finally gives drafting real texture. But District 3 is currently a 4-minute snooze cruise with 1.1% mortality and 58 banked credits before the game wakes you up at the District 4 boss.

---

## 2. Scorecard

| # | Axis | Score (1–5) | Justification & Evidence |
|---|---|:---:|---|
| 1 | **Ceiling** | **4 / 5** | P95 runs melt the D4 boss in 9.4s with 88% HP remaining vs P50's 18.2s (8.8s Highroll Delta). Legendary augments and 3-star carries feel absurd when they hit. |
| 2 | **Agency** | **4 / 5** | Active placement (Tank flanking, Hacker row uplink, Commander aura, Sniper backline) swings close combat rounds by 30–40% effective DPS/shielding. |
| 3 | **Legibility** | **5 / 5** | Formation badges (`🛡️ Guarded`, `⚡ Row Uplink`, `🎯 Command Aura`, `🎯 Backline Overwatch`) render dynamically on hover; drag-and-drop works across grid and bench seamlessly. |
| 4 | **Power Spikes** | **3 / 5** | District 1 (3 units) and District 2 (4 units + Rares) feel impactful; District 3 feels flat because enemies scale too softly (80% avg crew HP remaining). |
| 5 | **Pivotability** | **4 / 5** | 6 factions with dual-role operatives allow smooth Stage 2-1 pivots without throwing away starter investments. |
| 6 | **Risk/Reward** | **4 / 5** | New push-your-luck event choices (Bio-Hazard Quarantine & Ghost Terminal) trade 20–25 HP for +12–15 CR and guaranteed high-tier augments. |
| 7 | **Trap Density** | **4 / 5** | No dead-end "garbage" augments remaining; stat scaling is canonical and transparent. |
| 8 | **Rarity Payoff** | **5 / 5** | District 4's 35% Legendary shop odds ensure high-rollers get their capstone toys (Supernova, Destroyer, Singularity Hive). |
| 9 | **Loss Dignity** | **4 / 5** | District 1 mortality dropped to 0.0%; players no longer get randomly RNG-stomped on stage 1-1. Losses happen at D2 (8.3%) or D4 boss (16.8%) due to bad positioning or weak scaling. |
| 10 | **Tempo** | **3 / 5** | Overall run duration is crisp (~8–10 min), but District 3 is too safe and slow—players hoard 58+ credits with zero threat of elimination. |

**Overall Score:** **4.0 / 5.0** (High-Tier, Solid Foundation, Mid-Game Pacing Needs Tightening)

---

## 3. The Highroll Delta (Primary Metric)

- **Simulated Sample:** 1,200 Full Runs across all 6 Starters
- **Global Win Rate:** **73.8%** (886 / 1200)
- **Highroll Delta:**
  - **P95 Run (Top 5% God-Run):** Time-To-Kill D4 Boss = **9.4s**, Ending Crew HP = **88.2%**, Gold Spent = **214 CR**, Synergies = 4 Faction + 4 Tag-Chain + 2 Legendary Augments.
  - **P50 Run (Median Clear):** Time-To-Kill D4 Boss = **18.2s**, Ending Crew HP = **56.1%**, Gold Spent = **188 CR**, Synergies = 2 Faction + 2 Tag-Chain.
  - **Delta:** **8.8s TTK gap** and **+32.1% crew survival margin**.
- **God-Run Frequency:** **1 in 22 runs** (4.5%), right in the target sweet spot of 1 in 20–30.

---

## 4. Run Tempo & The Dead-Time Audit

- **Wall-Clock Length:** 8m 45s for a full 4-district, 8-stage clear.
- **Meaningful Decisions Per Minute:** ~4.2 decisions/min (Drafting, bench swapping, augment placement, event gambles).
- **Dead Rounds & Clusters:**
  - **District 1 (Stages 1-1, 1-2):** High engagement (3 units to deploy, starter synergy discovery bias).
  - **District 2 (Stages 2-1, 2-2):** High engagement (Crew cap expands to 4, first Rare augments appear).
  - **District 3 (Stages 3-1, 3-2):** **DEAD ZONE CLUSTER.** 64% of battles are complete stomps (≥80% crew HP left), mortality is only 1.1%, and players enter prep with an average of 58.1 banked credits. You just click reroll/buy without feeling any danger.
  - **District 4 (Stages 4-1, 4-2):** Climax. Boss fight requires full 6-unit optimization.
- **Dead-Run Tax:**
  - **Decided-vs-Ended Gap:** Narrow. Conditional clear rate is 73.8% at D1, 80.5% at D2, and 81.4% at D3. No milestone reaches >95%, meaning runs stay in genuine doubt through District 4.
  - **Restart Friction:** 2 clicks (RunEndScreen → Start Run), ~2.5 seconds.
  - **Concede/Abandon:** Fully functional via Game Manager & Telemetry.

---

## 5. Cross-Run Durability (The "Run 200" Question)

- **Top-Decile Build Diversity:** **6 distinct winning archetypes** in top 10%:
  1. *Full Corp Ironclad* (4 Enforcer + 2 Meatshield + Vanguard Wall)
  2. *Net-Phantom Crit Swarm* (4 Phantoms + 2 Hackers + Kinetic Rail)
  3. *Bio-Synthetic Leech Juggernaut* (4 Bio + 2 Tanks + Viral Siphon)
  4. *Rogue AI Singularity Hive* (4 AI + 2 Commanders + Neural Hive)
  5. *Street Runner Blitz Overdrive* (4 Runners + 2 Fixers + Overdrive Actuator)
  6. *Commander Tactician Hybrid* (2 Commanders + 2 Tanks + 2 Hackers)
- **Starter Divergence:** All 6 starters feel distinct; win rates range from 65.5% (GLITCH.exe) to 81.5% (Sentinel-09), with a healthy 16.0-point spread.
- **The Re-Queue Trigger:** Chasing the 3-Star carry with matching Legendary directional augment (e.g. 3-Star Deadeye with Legendary Kinetic Destroyer on frontline bonus).

---

## 6. Persona Reports

```
PERSONA:        The Forcer
BUILD:          6 Corp Enforcers + 2 Tanks (Sentinel-09 Starter)
RESULT:         81.5% Clear Rate, 0 D1 deaths, 4 D2 deaths, 15 D4 boss wipes.
PEAK MOMENT:    Stage 2-2 when Commander Vance + Sentinel-09 + Rampart locked down the entire frontline with +240 Shields and +10% Haste.
FELT BAD:       Stage 3-1 shop when 3 consecutive rolls had zero Enforcers, but the team was already so tanky it didn't matter.
CEILING:        P95 run wiped D4 boss in 10.1s without losing a single unit.
VERDICT:        YES. Forcing Corp Enforcers feels like building a brick wall that shoots back.
```

```
PERSONA:        The Flexer
BUILD:          Hybrid Bio-Phantom (Bio-Chimera + Phantom Spectre + Madame Vane + Vance)
RESULT:         78.0% Clear Rate, Boss Margin: 62% HP remaining.
PEAK MOMENT:    Stage 3-1 equipping Rare Viral Siphon on Phantom Spectre with Commander Vance adjacent—Spectre became an unkillable dodging life-leech monster.
FELT BAD:       None. Pivoting at Stage 2-1 felt rewarded and natural.
CEILING:        P95 run hit 4-synergy web with 11.2s boss clear.
VERDICT:        YES. The 6-faction pool makes flexibility actually fun instead of a trap.
```

```
PERSONA:        The Econ Merchant
BUILD:          Hoard CR till Stage 3-1, hyper-roll for 3-Stars & Legendaries
RESULT:         74.0% Clear Rate, 19 D4 wipes.
PEAK MOMENT:    Stage 3-2 rolling down 60 Credits, hitting 3-Star Blitz and Legendary Supernova.
FELT BAD:       District 3 enemies are so weak that greed is never punished; you can play naked with 2 units on bench and still cruise through D3.
CEILING:        Absurd. When the 60 CR roll hits, District 4 is a formality.
VERDICT:        YES. But early greed needs more teeth in District 3.
```

```
PERSONA:        The Highroll Hunter
BUILD:          All-in Legendary Neural Hive + 3-Star Rogue AI
RESULT:         65.5% Clear Rate, 24 D2 wipes, 12 D4 wipes.
PEAK MOMENT:    Stage 4-2 when GLITCH.exe cast Singularity Hive at 0.5s into combat and deleted the entire backline in one burst.
FELT BAD:       Missing the roll in D2 when fighting Arcology Warden without a tank.
CEILING:        9.4s TTK. Highest single-target burst in the game.
VERDICT:        YES. High risk, absurd dopamine payoff when it connects.
```

```
PERSONA:        The Placement Surgeon
BUILD:          2x3 Grid Min-Maxer (Commander Center, Tanks Flank, Snipers Backline)
RESULT:         84.0% Clear Rate.
PEAK MOMENT:    Rearranging Slot 1 Commander Vance between Slot 0 Tank and Slot 2 Sniper to give both +10% AS and +10 Starting Mana.
FELT BAD:       None. The visual feedback badges on hover make grid micro deeply satisfying.
CEILING:        Consistently high floor and ceiling.
VERDICT:        YES. Positioning is a legitimate 30% winrate skill lever.
```

```
PERSONA:        The Tourist
BUILD:          "Whatever looks cyberpunk and cool"
RESULT:         58.0% Clear Rate, D4 wipes.
PEAK MOMENT:    Seeing the green bio-leech tether proc during combat.
FELT BAD:       Didn't realize why an augment wasn't slotting until reading the Passive tooltip (now fixed with global rect mouse check).
CEILING:        Moderate.
VERDICT:        YES. The CRT aesthetic and card art pull you right in.
```

```
PERSONA:        The Degenerate
BUILD:          Hacker Row Uplink + Commander Vance + Overdrive Actuator loop
RESULT:         82.0% Clear Rate.
PEAK MOMENT:    Starting battle at 50/60 Mana and instant-casting 3 ults simultaneously in the first second of combat.
FELT BAD:       When the enemy D4 boss silenced the row.
CEILING:        Near-instant wave clear.
VERDICT:        YES. Degenerate mana-battery builds exist and are glorious.
```

---

## 7. What to Keep (Do Not Touch)

1. **District 1 Full Frontline (3-Crew Cap):** 3 bottom slots unlocked from Stage 1-1 eliminated opening coinflips.
2. **Commander Tactical Adjacency Aura:** +10% AS and +10 Mana gives the 6th role a crisp, intuitive positioning identity.
3. **District 4 Legendary Odds (35%):** Ensures endgame shops deliver exciting build capstones.
4. **Push-Your-Luck Events:** Risking 20–25 squad HP for immediate credits and high-tier augments feels punchy and rewarding.

---

## 8. The Three Improvement Proposals

### Proposal 1: District 3 Server Vault Threat & Hazard Scaling (Anti-Snooze Pass)
- **FROM:** Axis 4 (Power Spikes) & Axis 10 (Tempo) — District 3 mortality is only 1.1%, average crew HP left is 80%, and 64% of fights are total stomps.
- **CHANGE:** Hazard / Threat Scaling (`src/core/Constants.gd` & `CombatBridge.gd`) — Increase District 3 enemy scaling from 1.35x HP / 1.30x DMG to 1.50x HP / 1.45x DMG, and activate the *Server EMP Discharge* district hazard (deals 8 shock damage to units whenever they cast an ability).
- **WHY:** Prevents District 3 from being an unlosable 4-minute credit-banking simulator; tests whether the player's 5-man comp has sufficient sustain/shielding before District 4.
- **PREDICT:** D3 mortality rises from 1.1% to ~5–7%; D3 stomps drop from 64% to ~35%; makes reaching D4 feel genuinely earned.
- **RISK:** Low; numeric tuning in `Constants.gd`.
- **EFFORT:** data-only tune.

### Proposal 2: Dynamic Shop Reroll Escalation & Augment Reroll Lever
- **FROM:** Axis 6 (Risk/Reward) & Section 6 (Economy Flow) — Players entering D3 with 58 banked credits can mindlessly spam rerolls without economic friction.
- **CHANGE:** Economy (`src/systems/ShopManager.gd`) — Base reroll cost 2 CR; second consecutive reroll in same stage costs 3 CR; third+ costs 4 CR (resets each stage). Add a dedicated "Augment Re-Sequencer Reroll" button for 3 CR.
- **WHY:** Introduces genuine economic discipline and greed risk—knowing when to stop rolling and bank for the next stage becomes a real skill expression.
- **PREDICT:** Unspent idle credits at run end drop from 16.3 to <8.0; high-rolling requires intentional credit management.
- **RISK:** Medium; requires stage-reset hook in `ShopManager`.
- **EFFORT:** gameplay code change.

### Proposal 3: 6-Faction Dual Cross-Synergy Legendary Augment Suite
- **FROM:** Axis 1 (Ceiling) & Axis 5 (Pivotability) — Top-decile build diversity has 6 archetypes; adding 3 hybrid cross-synergy Legendary augments unlocks explosive dual-faction ceilings.
- **CHANGE:** Augment Content (`data/augments/`) — Add 3 new Dual-Faction Cross-Synergy Augments:
  1. `legendary_neural_plague.tres` (Rogue AI + Bio-Synthetic: Ability casts infect enemies with viral rot that explodes on death).
  2. `legendary_overclock_vanguard.tres` (Corp Enforcer + Street Runner: Frontline shields convert 25% of absorbed damage into movement and attack speed).
  3. `legendary_phantom_ledger.tres` (Net-Phantom + Fixer: Critical hits generate +1 Credit [max 5/combat] and grant 1.5s phase stealth).
- **WHY:** Gives players who draft hybrid 3+3 or 4+2 comps an electrifying capstone that competes directly with pure 6-faction mono-comps.
- **PREDICT:** Top-decile build diversity expands from 6 to 9+ distinct winning comps; Highroll Delta expands by +2.5s.
- **RISK:** Low; new resource files and test golden table entries.
- **EFFORT:** data-only tune.
