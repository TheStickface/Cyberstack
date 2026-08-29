# Marvin Manager — Cyberstack Gameplay Proposals Backlog

This document is the continuous backlog of gameplay change proposals generated across Marvin Manager design passes.

**Status Legend:**
- `new` — Proposed, not yet triaged by the user.
- `picked` — User wants it implemented (handed off to `/cyberstack-balance`).
- `rejected` — User rejected this proposal.
- `done` — Implemented in the real repository.

---

## Pass 1 (2026-08-29)

#1 District 3 & 4 Threat Scaling Rebalance
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals.md)
ORIGIN:     Simon Seer — Apex Escalation
CHANGE:     Update Constants.DISTRICT_ENEMY_SCALING for District 3 (hp_mult: 1.75, dmg_mult: 1.45) and District 4 (hp_mult: 2.25, dmg_mult: 1.70).
EVIDENCE:   2,000-run simulation reduced premature D2 clear certainty from 96.6% to 88.4%; D4 deaths increased from 2.9% to 10.1%; global win rate settled at 77.65%.
PREDICT:    Eliminates coasting through late districts; keeps all 4 starters within the 10–20 point strategy spread.
RISK:       Low risk; purely data/constant tuning.
EFFORT:     data-only tune (Constants.gd)

#2 Black Market Augment Re-sequencing Credit Sink
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals.md)
ORIGIN:     Simon Seer — Overclock Re-sequencer
CHANGE:     Add a late-game shop action allowing players to spend 5 Credits to reroll an equipped augment's secondary tag/trigger.
EVIDENCE:   Baseline telemetry showed 28.4% of runs ending with >20 unused credits due to lack of meaningful post-District 3 credit sinks.
PREDICT:    Reduces end-of-run idle gold below 8 credits and raises high-roll skill ceiling.
RISK:       Medium; requires UI button on PrepScreen and shop economy integration.
EFFORT:     sim + game code (ShopManager.gd, PrepScreen.gd)

#3 Starter Corp Sentinel-09 Base Health Reinforcement
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals.md)
ORIGIN:     Simon Seer — Aegis Protocol
CHANGE:     Increase corp_sentinel.tres base health from 550 to 600 (StatType.MAX_HEALTH: 600).
EVIDENCE:   In District 1 with crew cap 2, Sentinel-09 had lower early survivability before 4-faction threshold armor kicked in.
PREDICT:    Narrows early D1 dropoff for Corp Enforcer starter without increasing late-game peak.
RISK:       Very low; single .tres stat adjustment.
EFFORT:     data-only tune (data/units/corp_sentinel.tres)

#4 District 3 Minion 5-Operative Compositions
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals.md)
ORIGIN:     Simon Seer — Vault Security Swarm
CHANGE:     Expand BalanceSimulator._build_minion_enemy_comp and CombatBridge D3 enemy templates from 4 to 5 units to match player tactical grid expansion.
EVIDENCE:   In baseline D3, player crew has 5 fielded operatives while enemy minion comps only fielded 4, causing 82.5% combat stomps and 0.1% mortality.
PREDICT:    Reduces D3 combat stomp rate from 82.5% to ~45% and raises D3 mortality to ~4-6%.
RISK:       Low; adjusts enemy team generator in CombatBridge.gd and BalanceSimulator.gd.
EFFORT:     sim + game code

---

## Pass 2 (2026-08-29)

#5 Rogue AI Starter & Subnet Sync AP Reinforcement
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass2.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass2.md)
ORIGIN:     Simon Seer — Overclock Subnet
CHANGE:     Unit stats & Faction bonus (data/units/ai_glitch.tres, data/factions/rogue_ais.tres) — ai_glitch base AP (65 → 72), Max Health (620 → 650), Starting Mana (40 → 45); Rogue AI (2) AP bonus (+15 → +25).
EVIDENCE:   1,000-run simulation raised GLITCH.exe win rate from 60.4% to 65.6%, closing the gap with Blitz (62.4%), Sentinel (65.2%), and Vane (66.4%).
PREDICT:    Tightens 4-starter strategy spread within 5 points and makes Rogue AI drafted comps viable from node 1.
RISK:       Very low; pure data-only .tres tuning.
EFFORT:     data-only tune

#6 District 3 Server Vault Enemy Threat Calibration
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass2.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass2.md)
ORIGIN:     Simon Seer — Data Surge Sentinels
CHANGE:     District Enemy Scaling (src/core/Constants.gd) — Set District 3 hp_mult: 1.95 and dmg_mult: 1.55.
EVIDENCE:   1,000-run simulation reduced D3 combat stomp rate from 53.6% to 37.5% and brought won-battle crew HP to 75%.
PREDICT:    Replaces mid-game coasting with active tactical engagement before the D4 boss.
RISK:       Low; single dictionary entry in Constants.gd.
EFFORT:     data-only tune

#7 Legendary Thermal Supernova AP Amplification
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass2.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass2.md)
ORIGIN:     Simon Seer — Supernova Catalyst
CHANGE:     Augment tuning (data/augments/legendary_thermal_supernova.tres) — Base AP +60 → +75, armor_melt_pct 0.40 → 0.50.
EVIDENCE:   Expands Highroll Delta to ~8.80s and increases top-decile build diversity for AP/thermal carry builds.
PREDICT:    Enhances dopamine spike when finding Legendary shop drops in late districts.
RISK:       Very low; single .tres resource update.
EFFORT:     data-only tune

#8 Ghost Terminal Push-Your-Luck Risk/Reward
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass2.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass2.md)
ORIGIN:     Simon Seer — Deep Net Access
CHANGE:     Event choice reward scaling (data/events/event_ghost_terminal.tres) — Choice 2 "Siphon Deep Core Ledgers" grants +12 Credits but inflicts 15.0 crew HP damage (penalty_health_cost: 15.0).
EVIDENCE:   Creates authentic tension in event nodes where players must balance greed against survival before combat encounters.
PREDICT:    Adds meaningful risk/reward trade-offs to narrative nodes.
RISK:       Very low; single .tres resource update.
EFFORT:     data-only tune
