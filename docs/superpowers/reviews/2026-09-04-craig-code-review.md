# Craig Coder — Engineering Review: Autoplay Spectator Bot & Combat Parity

## Verdict

Building a headless-drivable "watch the game play itself" tool immediately surfaced two real, pre-existing engineering defects in code no automated test had ever exercised end-to-end — one cosmetic, one a genuine balance-integrity bug (Armor and Evasion have been non-functional in live combat while the balance reports assumed they worked). All three are fixed and covered by new regression tests; the standing gap this leaves is that **nothing in the test suite drives a full run through the real UI screens**, which is exactly why these went unnoticed.

## Scope

- **Trigger:** building `src/tools/AutoplayDirector.gd`, a live spectator bot that drives an actual game run (real `ShopManager`/`CrewManager`/`RunManager`/`GameManager`, real `PrepScreen`/`DistrictMapScreen`/`CombatMockArena` screens) rather than the synthetic `BalanceSimulator` model, at human-watchable pace.
- **What was reviewed:** the three systems the bot is the first thing to have ever exercised together, headless, at volume: `PrepScreen`'s refresh lifecycle, `OperativeCard`'s equipped-augment tooltip rendering, and `CombatMockArena`'s combatant stat model.
- **Commit at time of writing:** `49e33c7` (`feat(combat): integrate armor and evasion stats and formation bonuses into CombatantState`) — the combat-parity fix landed there via the shared working tree; the two UI-refresh findings landed in `9a96789`/nearby commits the same way. This doc formalizes what was found and why, since it happened live rather than as a planned review pass.
- **Test suite status:** 23 suites / 605 assertions, all passing (`godot --headless -s tests/test_runner.gd`). Three new regression tests added: `tests/test_strategy_archetypes.gd`, `tests/test_combat_mock_arena.gd`, plus the `test_runner.gd` registration.
- **Verification method:** `godot --headless --path . res://src/ui/screens/Main.tscn --autoplay --autoplay-speed=0.1`, run to completion multiple times, checked for `SCRIPT ERROR` output.

## Findings (severity-ranked)

### 1. [HIGH — balance integrity] Armor and Evasion did nothing in real combat

**What:** `CombatMockArena.CombatantState` never declared `armor`/`evasion` fields. `_create_combatant` never initialized them from a unit's base stats or formation bonuses, and `_apply_damage`/`_perform_auto_attack` never referenced them at all — no mitigation formula, no dodge roll. `BalanceSimulator.gd` (the model every balance report in `docs/superpowers/reviews/` and `data/balance_simulation_report.md` is built on) has always modeled both correctly: a full evasion dodge-roll and a `100/(100+armor)` diminishing-returns damage formula, plus Thermal-tag armor shred.

**Where:** `src/ui/screens/CombatMockArena.gd` (`CombatantState` class def, `_create_combatant`, `_perform_auto_attack`) vs. `src/tools/BalanceSimulator.gd:688-731,915-990` (the correct reference model).

**Why it matters:** Corp Enforcer's "Aegis Protocol" armor half, Bio-Synthetic's "Mutagenic Plating"/"Apex Mutation" armor stacking, Net-Phantom's "Cloak Protocol"/"Phase Infiltration" evasion, and any augment or directional passive granting Armor/Evasion had zero effect on any fight a player actually watched — despite two of the six factions building their entire identity around these stats, and every balance report assuming they function. This is exactly the sim/live-game parity gap `cyberstack-balance` treats as its #1 risk (`src/tools/BalanceSimulator.gd`'s own doc comment: "Sim drift is the #1 source of false balance reads"), just running in the direction nobody was checking — the sim was right, the live game was silently missing the mechanic. Every existing balance number for those three factions describes a game state players were never actually playing.

**How it was found:** `_apply_mods_to_combat_state` (the one place `ARMOR`/`EVASION` were referenced, for directional formation passives) threw `Invalid access to property or key 'armor'` the first time a real equipped augment or formation passive granted one. No existing test ever equipped an augment onto a unit and ran that unit into combat headless — `AutoplayDirector` was the first thing to do both in the same process.

**Fix (applied):** Added `armor`/`evasion` fields to `CombatantState`; wired them through `_create_combatant` (base stat, formation bonus, and the no-unit fallback branch, matching every other stat's existing pattern); added the evasion dodge-roll, armor mitigation formula, and Thermal-tag shred to `_perform_auto_attack`, formula-for-formula matching `BalanceSimulator`'s model.

**Automation:** `tests/test_combat_mock_arena.gd` now pins `_create_combatant`'s armor/evasion initialization (base stat and formation-bonus paths) and the directional-mod crash path directly. The deeper gap — nothing exercises `CombatMockArena` inside a full headless run — is its own automation opportunity; see below.

**Handoff:** `/cyberstack-balance` — the Monte Carlo report at `data/balance_simulation_report.md` should be re-run now that live combat matches it; Corp Enforcer/Bio-Synthetic/Net-Phantom clear rates were measured against a model of themselves that wasn't actually running. `/cyberstack-userreview` — worth a fresh pass specifically on whether these three factions now *feel* like their stated identity, since this is the first time their signature stat has ever been live.

### 2. [MEDIUM — engineering, discovered enabling the bot] `PrepScreen` never refreshes mid-shop-visit under programmatic state changes

**What:** `GameManager.state_changed` — the only signal that makes `Main.gd` rebuild the currently-shown screen — fires once on entering `PREP`, then not again for the rest of that shop visit (multiple buys/rerolls/equips all happen while state stays `PREP`). A screen driven by direct manager calls instead of its own click handlers (which manually call `_refresh_all()` after each action) will look frozen even though the underlying data is changing correctly underneath it.

**Where:** `src/ui/screens/Main.gd` (`_on_game_state_changed` / `_show_screen_for_state`) — state-change-triggered rebuild is the only refresh path; `src/ui/screens/PrepScreen.gd:79` (`_refresh_all`) is otherwise only called from the screen's own button handlers.

**Why it matters:** This is a latent trap for any future code that drives the shop programmatically (an integration test, a tutorial auto-play, a future AI opponent) — it will look broken (or, worse, name the wrong item after a reroll invalidates what's still on screen) while actually working correctly, which is a confusing failure mode to debug from the outside.

**Fix (applied):** `AutoplayDirector._refresh_prep_screen_ui()` casts the currently-shown screen to `PrepScreen` and calls `_refresh_all()` every tick — a pure redraw, no side effects, safe every 2s.

**Automation:** None proposed — this is a consequence of `PrepScreen` intentionally not polling every frame (correct for a real UI), not a defect in `PrepScreen` itself. Anything else driving it programmatically needs to know to do the same.

**Handoff:** None.

### 3. [MEDIUM — engineering, pre-existing] `OperativeCard` crashes rendering any equipped augment's tooltip

**What:** `["STATS"] + aug.get_stat_lines()` concatenates an untyped array literal with a typed `Array[String]` return using `+`; in GDScript 4 this loses the type annotation, and assigning the untyped result to a `var aug_lines: Array[String]` throws `Trying to assign an array of type "Array" to a variable of type "Array[String]"`.

**Where:** `src/ui/components/OperativeCard.gd:470` (now fixed), inside `_refresh_slots()`, called from `_update_ui()` → `setup()` → `PrepScreen._build_grid_slot_cell()`.

**Why it matters:** This isn't specific to the autoplay bot — `PrepScreen`'s own `_on_augment_dropped_on_unit` drag-and-drop handler calls `_refresh_all()` immediately after a manual equip, hitting the identical code path. Any real player equipping any augment onto any unit via normal drag-and-drop should have hit this. It was invisible until now only because nothing had exercised a live `_refresh_all()` call with a real equipped augment present in an automated/headless context where the error surfaces in captured output instead of scrolling past in an interactive session.

**Fix (applied):** `["STATS"] + aug.get_stat_lines()` → `var aug_lines: Array[String] = ["STATS"]; aug_lines.append_array(aug.get_stat_lines())`.

**Automation:** `gdlint`-style rule (or a simple grep-based CI check) flagging `Array[T] = <literal> + <expr>` patterns — the untyped-literal-plus-typed-array construct is a general GDScript 4 footgun, not unique to this file. Worth a project-wide grep for the same pattern elsewhere.

**Handoff:** None.

## What to keep

- **`BalanceSimulator`'s combat model is correct and was the reference implementation for the fix above** — its armor/evasion/thermal-shred formulas needed zero changes, only porting. Whoever wrote that math got it right; the gap was purely that the live game never got a matching implementation.
- **The manager layer (`ShopManager`/`CrewManager`/`RunManager`, all plain `RefCounted`) is trivially drivable outside the UI.** `AutoplayDirector` could call `buy_unit_slot`/`reroll_shop`/`deploy_bench_to_grid`/`equip_augment_from_inventory` directly with zero scaffolding — this is exactly the "systems know nothing about UI" layering the project already follows, and it's what made a full programmatic run possible at all.
- **`GameManager.state_changed` as the single state-transition hook** made `Main.gd` swap real screens correctly for every state the bot drove into (MAP/PREP/COMBAT/RUN_END) with no bot-side scene-management code needed — the one gap (PREP not re-firing mid-visit) is a narrow, well-understood exception, not a design flaw.

## Automation opportunity: a real end-to-end smoke test

Every finding above was invisible to the existing 20-suite test corpus because no test drives a full run through the actual scenes (`PrepScreen`, `DistrictMapScreen`, `CombatMockArena`) the way a player experiences them — the suite tests managers and data in isolation, and `BalanceSimulator` tests the synthetic combat model, but nothing connects "a real equipped augment" to "a real rendered card" to "a real fight." `AutoplayDirector` run headless for ~30s with a fast tick rate (`--autoplay --autoplay-speed=0.1`) already *is* that smoke test in everything but name — it exercises shop buy/sell/reroll/equip/place, map navigation, event resolution, and combat resolution in one pass and prints any `SCRIPT ERROR` straight to console.

**Concrete proposal:** wrap that invocation (or a `SceneTree`-script equivalent that doesn't need a real Godot binary path assumption) in `tests/test_full_run_smoke.gd`, capping it at N frames or M completed runs, and register it in `test_runner.gd`. It would have caught all three findings above on the first CI run instead of during ad-hoc tool-building.

## Findings appendix

Covered in full above (each finding already carries What/Where/Why/Fix/Automation/Handoff). No additional findings beyond the three listed.
