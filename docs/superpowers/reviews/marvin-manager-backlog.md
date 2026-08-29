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
