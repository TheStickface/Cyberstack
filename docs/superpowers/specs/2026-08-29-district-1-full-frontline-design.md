# District 1 Full Frontline — Design

**Date:** 2026-08-29
**Status:** Approved, ready for planning

## Problem

District 1 unlocks only 2 tactical-grid slots (bottom-left `0`, bottom-center `1`).
The third frontline slot (bottom-right `2`) is gated to District 2, and the D1 field
cap is `2`. With only two operatives, players cannot reach past the first faction
synergy threshold or run a flex pick in the opening district, which suppresses
build diversity in the phase where players are forming their run identity.

## Goal

Enable all three bottom-row (frontline) slots from the start of District 1 so
players can field a full 3-wide frontline immediately, opening more synergy and
composition choices early — without making the enemy side of D1 harder.

## Decisions (locked)

- **Scope:** the unlock applies to all of District 1 (both subdistricts 1-1 and
  1-2). Nothing changes mid-district today, so this is equivalent to "from the
  first encounter."
- **Enemy scaling:** D1 enemies stay at 2 minions. The player gets a 3-vs-2
  advantage in the opening district by design.
- **D2+ untouched:** districts 2–5 keep their current crew caps (4/5/6/6) and
  slot-unlock schedule (slot 4 at D2, slot 3 at D3, slot 5 at D4).

## Core mechanic change

| Location | Before | After |
|---|---|---|
| `Constants.DISTRICT_CREW_LIMITS[1]` | `2` | `3` |
| `Constants` — new `DISTRICT_ENEMY_COUNTS` | (none) | `{1: 2, 2: 4, 3: 5, 4: 6, 5: 6}` |
| `CrewManager.is_slot_unlocked(2)` | `current_district >= 2` | `true` |
| `CrewManager.get_slot_unlock_district(2)` | `2` | `1` |
| `CrewManager.gd:14-18` doc comments | frontline = slots 0,1 | frontline = slots 0,1,2 all at D1 |
| `CombatBridge._generate_enemy_squad` enemy count source | `Constants.DISTRICT_CREW_LIMITS.get(district_id, 2)` | `Constants.DISTRICT_ENEMY_COUNTS.get(district_id, 2)` |

### Approach chosen

**Parallel `DISTRICT_ENEMY_COUNTS` constant.** Mirrors the existing
`DISTRICT_ENCOUNTER_PAYOUTS` / `DISTRICT_SHOP_ODDS` sibling-dict pattern in
`Constants.gd`. Enemy squad size becomes an explicit, independently-tunable
balance knob rather than a magic number inlined in combat logic
(rejected alternative B) or a per-theme resource field that would contradict
`DistrictResource.gd:5-7`'s "size derives from run position, not theme"
(rejected alternative C).

### Net effect

- D1 player fields up to 3 across a full frontline row (slots 0/1/2).
- D1 enemies stay 2-wide (minions), boss encounter still 2 minions + boss.
- D2 still adds backline-center slot 4 for its cap of 4; D2+ enemy counts
  unchanged because `DISTRICT_ENEMY_COUNTS` tracks `DISTRICT_CREW_LIMITS` for
  districts ≥ 2.

## Ripple effects

### Tests to update

- `tests/test_crew_manager.gd:158-183` — "District 1 cap = 2" scenario becomes
  cap = 3; deploy-into-open-slot and bench assertions shift accordingly
  (incl. the `:173` comment).
- `tests/test_crew_validator.gd` — check for D1 crew-size assertions expecting `2`.
- `tests/test_balance_simulator.gd:79-86` — sanity-check the benching setup
  against a D1 crew of 3 (comment at `:79` about D2 slot 4 is unaffected).
- `tests/test_data_integrity.gd`, `tests/test_district_thematics.gd` — scan for
  hardcoded `2` tied to D1 player cap.
- **New assertion** in `tests/test_data_integrity.gd`:
  `DISTRICT_ENEMY_COUNTS[d] == DISTRICT_CREW_LIMITS[d]` for every `d >= 2`, so
  the two dicts cannot drift apart for districts where they must match.

### Sim / metrics (see `dev-metrics-infra` memory)

- Re-run `BalanceSimulator.gd` headless (`--runs=10000`) → regenerates
  `data/balance_simulation_report.md`. **This is the validation gate.** The
  change lands directly on commit `19f7c91`'s Round 1 tuning; compare D1
  conditional clear-probability, combat closeness / victory margin, and
  economy / credit-flow sections before vs after.
- Re-run `PeterPlayerEvaluator.gd` for persona / TTK deltas.
- `BalanceExporter.gd:86` crew-capacity table auto-reflects the new cap — no
  code change.

### UI (auto-updates from the two `CrewManager` functions — verify only)

- `PrepScreen.gd:172-173` — slot 2 renders unlocked at D1 with no "unlocks in
  District N" hint.
- `DistrictMapScreen.gd:137` — "Crew cap increased to %d" on the D1→D2 advance
  now reads 3→4 instead of 2→4. Correct as-is.
- `CombatMockArena.gd:90` — player header cap display pulls from
  `DISTRICT_CREW_LIMITS`, shows 3 for D1. Correct.

### Telemetry

- `TelemetryManager.gd:125` synthetic crews size from `DISTRICT_CREW_LIMITS` →
  D1 synthetic crews become size 3. Intended (matches real player capability).

## Acceptance criteria

1. In District 1, a player can field 3 operatives across bottom slots 0/1/2;
   `PrepScreen` shows all three frontline slots unlocked with no unlock hint.
2. District 1 non-boss combat spawns exactly 2 enemy minions; D1 boss encounter
   = 2 minions + boss, unchanged.
3. Districts 2–5 unchanged: caps 4/5/6/6, enemy counts match crew caps, backline
   slots unlock on the existing schedule.
4. All existing tests pass after updates; no hardcoded-`2` assertion remains for
   the D1 player field cap.
5. `BalanceSimulator` 10k-run report shows D1 clear-probability no worse than the
   `19f7c91` baseline (expectation: slightly easier — 3-vs-2 with more synergy
   access).

## Risks / watch-items

- **Early synergy acceleration.** Three D1 units let players hit the 2-unit
  faction threshold *and* run a flex pick, or field a partial 3-chain. Combined
  with `19f7c91`'s "early synergy shop bias", D1 could tip too easy. The sim
  report is the arbiter; if D1 clear-prob jumps hard, the follow-up lever is
  dialing back the shop bias, **not** re-gating the slot.
- **3-vs-2 economy.** Faster / cleaner D1 clears may raise credit inflow into D2.
  Check the economy & credit-flow section of the sim report.
- **Two sources of truth for enemy count.** `DISTRICT_ENEMY_COUNTS` and
  `DISTRICT_CREW_LIMITS` must stay in sync for D2+. Mitigated by cross-referencing
  comments on both dicts and the new `test_data_integrity` equality assertion.

## Out of scope

- Rebalancing the D2+ slot / crew-cap schedule.
- Per-subdistrict enemy scaling within a district.
- Enemy squad *composition* changes (faction, tier, augment loadout).
- Dialing back the `19f7c91` early synergy shop bias (only revisited if the sim
  report shows D1 became too easy).
