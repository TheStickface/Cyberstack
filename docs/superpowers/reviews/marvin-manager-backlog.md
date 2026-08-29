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

---

## Pass 3 (2026-08-29)

#9 Rare Kinetic Overdrive Attack Speed & Armor Reinforcement
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass3.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass3.md)
ORIGIN:     Simon Seer — Overdrive Kinetic Recoil
CHANGE:     Augment stats (data/augments/rare_kinetic_overdrive.tres) — Increase Attack Speed from +20% to +25% and Armor from +12 to +16.
EVIDENCE:   1,000-run simulation demonstrates improved tempo for frontline bruisers without inflating overall run winrates past targets.
PREDICT:    Increases pick rate of defensive kinetic slots in D2/D3 shops.
RISK:       Very low; single .tres resource adjustment.
EFFORT:     data-only tune

#10 District 2 Shop Recruitment Odds Calibration
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass3.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass3.md)
ORIGIN:     Simon Seer — Underground Brokerage Odds
CHANGE:     Economy / Shop Odds (src/core/Constants.gd) — Set DISTRICT_UNIT_SHOP_ODDS[2] to { 1: 0.50, 2: 0.40, 3: 0.10 }.
EVIDENCE:   Provides earlier access to 4-cost and 5-cost key units in District 2, improving pivot flexibility.
PREDICT:    Increases unique endgame winning compositions and reduces feeling of locked build paths.
RISK:       Low; single dictionary entry in Constants.gd.
EFFORT:     data-only tune

#11 Common Viral Nanites Attack Speed & AP Utility
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass3.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass3.md)
ORIGIN:     Simon Seer — Nanite Contagion Cascade
CHANGE:     Augment stats (data/augments/common_viral_nanites.tres) — Increase Attack Speed from +8% to +14% and add +10 Ability Power.
EVIDENCE:   Elevates the lowest-performing common augment to a competitive early draft pick.
PREDICT:    Increases viral synergy adoption in District 1 and 2.
RISK:       Very low; single .tres resource update.
EFFORT:     data-only tune

#12 Underground Betting Ring High-Roller Stakes
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass3.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass3.md)
ORIGIN:     Simon Seer — Skyline Wager High Stakes
CHANGE:     Event choice balancing (data/events/event_underground_betting_ring.tres) — Choice 2 purse increased to 18 Credits with a 20.0 crew HP penalty cost (penalty_health_cost: 20.0).
EVIDENCE:   Aligns narrative events with high-stakes cyberpunk risk/reward identity.
PREDICT:    Adds compelling tactical decision-making when low on health vs low on credits.
RISK:       Very low; single .tres resource update.
EFFORT:     data-only tune

---

## Pass 4 (2026-08-29)

#13 Bio-Synthetic Biograft Plating & Chimera Frontline Durability
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass4.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass4.md)
ORIGIN:     Simon Seer — Biograft Regenerative Weave
CHANGE:     Unit & Faction Stats (data/units/bio_chimera.tres, data/factions/bio_hackers.tres) — Bio-Chimera Max Health 800 → 850, Base AD 34 → 38; Bio-Synthetic (2) bonus +160 HP and +8 Armor.
EVIDENCE:   1,200-run simulation raised Bio-Chimera win rate from 44.5% to 48.0% and tightened 6-starter strategy spread to 15.5 points.
PREDICT:    Prevents early D1-1 dropoffs for Bio-Synthetic starters without altering late-game boss mortality.
RISK:       Very low; pure data .tres adjustment.
EFFORT:     data-only tune

#14 Net-Phantom Wraith Shroud Starting Mana & Evasion
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass4.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass4.md)
ORIGIN:     Simon Seer — Spectral Mirage Shroud
CHANGE:     Unit & Faction Stats (data/units/phantom_spectre.tres, data/factions/net_phantoms.tres) — Spectre Starting Mana 0/60 → 20/60; Net-Phantom (2) Evasion +15% → +20%.
EVIDENCE:   1,200-run simulation raised Net-Phantom win rate from 49.5% to 53.5% and stabilized early D1/D2 survival.
PREDICT:    Enables glass-cannon assassin drafting to contest D2/D3 enemy formations without requiring lucky tank drops.
RISK:       Very low; pure data .tres update.
EFFORT:     data-only tune

#15 District 4 Black Market Legendary Augment Siphon Odds
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass4.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass4.md)
ORIGIN:     Simon Seer — Black Market Singularity Nodes
CHANGE:     Economy / Shop Odds (src/core/Constants.gd) — Set DISTRICT_SHOP_ODDS[4] Tier-3 (Legendary) odds to 0.35 (up from 0.20).
EVIDENCE:   Highroll Delta increased from 8.8s to 11.2s; endgame clears feel distinctly powerful with completed legendary augment synergy.
PREDICT:    Eliminates dead credit accumulation in Stage 4-1 and 4-2 by offering attractive 5-credit legendary augments.
RISK:       Low; single dictionary entry in Constants.gd.
EFFORT:     data-only tune

#16 Bio-Hazard Quarantine High-Yield Siphon Risk Branch
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass4.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass4.md)
ORIGIN:     Simon Seer — Contagion Ledger Extraction
CHANGE:     Event Balancing (data/events/event_bio_hazard_quarantine.tres) — Choice 2 "Extract Experimental Serum" grants +15 Credits and 1 Rare Augment roll for 20.0 HP crew penalty.
EVIDENCE:   Adds a high-stakes tactical branch to newly introduced bio-hazard narrative nodes.
PREDICT:    Provides healthy risk/reward tension before entering Stage 2-1 or 3-1 mini-boss encounters.
RISK:       Very low; single event resource update.
EFFORT:     data-only tune

---

## Pass 5 (2026-08-29)

#17 Commander Tactical Grid Adjacency Aura
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass5.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass5.md)
ORIGIN:     Simon Seer — Overclock Command Array
CHANGE:     Tactical Formations (src/systems/CrewManager.gd) — Add Commander formation aura granting +10% Attack Speed and +10 Starting Mana to adjacent allies.
EVIDENCE:   1,200-run simulation lifted Rogue AI win rate from 59.5% to 64.0% and narrowed strategy spread to 15.5 points.
PREDICT:    Gives the Commander role a distinct tactical identity on the grid and encourages hybrid formation planning.
RISK:       Low; isolated calculation in CrewManager.calculate_formation_bonuses.
EFFORT:     gameplay code change

#18 Bio-Phantom Neuro-Toxic Siphon Cross-Synergy Augment (Rare)
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass5.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass5.md)
ORIGIN:     Simon Seer — Venomous Phase Shift
CHANGE:     Augment Stats (data/augments/rare_viral_siphon.tres) — Stat modifiers: +18 AD, +10% Evasion; life-steal drain on crit.
EVIDENCE:   Supports cross-faction drafting between Bio-Synthetics and Net-Phantoms in Stages 2-1 through 3-2.
PREDICT:    Reduces pure mono-faction lock-in during mid-game shop transitions.
RISK:       Very low; single augment .tres update.
EFFORT:     data-only tune

#19 District 2 & 3 Encounter Credit Pacing Curve
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass5.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass5.md)
ORIGIN:     Simon Seer — Syndicate Dividend Rebalance
CHANGE:     Economy / Payouts (src/core/Constants.gd) — Set DISTRICT_ENCOUNTER_PAYOUTS for District 2 and 3 to 5 Credits (up from 4).
EVIDENCE:   Prevents mid-run credit starvation when expanding crew cap from 3 to 5 units in 8-stage runs.
PREDICT:    Maintains a healthy reroll tempo across Stages 2-1 to 3-2.
RISK:       Low; dictionary adjustment in Constants.gd.
EFFORT:     data-only tune

#20 Abandoned Cyberware Lab High-Yield Terminal Risk Branch
STATUS:     done
PASS:       2026-08-29 → [2026-08-29-marvin-manager-proposals-pass5.md](file:///c:/Dev/Cyberstack/docs/superpowers/reviews/2026-08-29-marvin-manager-proposals-pass5.md)
ORIGIN:     Simon Seer — Neural Terminal Extraction
CHANGE:     Event Balancing (data/events/event_abandoned_cyberware_lab.tres) — Choice 2 "Extract Classified Blueprints" rewards +1 Rare Augment and +12 Credits for 25.0 HP crew penalty.
EVIDENCE:   Provides high-stakes push-your-luck decision before District 2 & 3 Bosses.
PREDICT:    Diversifies mid-run event decision density.
RISK:       Very low; single event resource update.
EFFORT:     data-only tune
