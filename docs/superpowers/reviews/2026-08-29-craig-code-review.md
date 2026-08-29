# Craig Coder — Cyberstack Code Review Report

**Date:** 2026-08-29  
**Reviewer:** Craig Coder (Staff Engineer, Code Health & Scalability)  
**Target Repository:** `C:\dev\cyberstack` (Godot 4.6 Singleplayer Auto-Battler Roguelite)  
**Target Branch:** `main` (commit `b9bf784` + recent sweep)

---

## 1. Verdict

> **Cyberstack's core data-driven architecture and combat simulation foundations are exceptionally solid, but the persistence layer and telemetry pipeline are NOT yet scale-ready for external distribution.**
> 
> The primary hazards are active-run save desynchronization (which drops tactical grid layouts and star levels on reload) and telemetry pollution/fragility (synthetic data overwriting real player records, unversioned integer enum serialization, and missing telemetry on abandoned runs).

---

## 2. Scope

- **Review Target:** Full codebase sweep with deep-dive inspection of recent commits (`HEAD~8..HEAD`: `b9bf784`, `830fdda`, `ec90353`, `d9232d0`, `dc455a7`, `608609e`, `cf7147c`, `9814949`).
- **Subsystems Inspected:**
  - `src/systems/TelemetryManager.gd`, `src/data/TelemetryEvent.gd`, `src/tools/AnalyticsEngine.gd`, `src/tools/ExportTelemetryReport.gd`
  - `src/systems/SaveManager.gd`, `src/systems/MetaManager.gd`, `src/systems/RunManager.gd`, `src/systems/CrewManager.gd`, `src/systems/ShopManager.gd`
  - `src/core/GameManager.gd`, `src/core/EventBus.gd`, `src/core/Constants.gd`, `src/core/Enums.gd`
  - `src/ui/screens/PrepScreen.gd`, `src/tools/PeterPlayerEvaluator.gd`, `src/tools/DataValidator.gd`
- **Headless Test Suite Status:**
  - **Passed:** 20 / 20 test suites (485 assertions passed, 0 failed).
  - **Data Validation:** 0 errors, 0 warnings across all 23 districts, 20 augments, 63 units, 13 narrative events.

---

## 3. Consistency Findings (Ranked by Severity)

| ID | Area | Severity | Defect Summary | Location |
|---|---|---|---|---|
| **C-1** | State Persistence | **High** | `SaveManager.save_active_run` fails to persist `tactical_grid` slot indices, `star_level`, or drawn `run_districts`. Upon loading, tactical grid is cleared and units lose star levels. | `src/systems/SaveManager.gd:54-64, 103-108, 127-159` |
| **C-2** | Layering & Encapsulation | **Medium** | `PrepScreen._on_unit_sell` manually mutates `shop_mgr.gold` and removes units directly instead of calling `shop_mgr.sell_unit()`, bypassing star refund multipliers and augment recovery. | `src/ui/screens/PrepScreen.gd:795-805` |
| **C-3** | Cross-System Event Flow | **Medium** | `EventBus` defines granular runtime signals (`unit_recruited`, `augment_equipped`, `shop_rerolled`, `narrative_event_resolved`), but `TelemetryManager` does not listen to them, resulting in zero in-run telemetry recording. | `src/core/EventBus.gd:7-38`, `src/systems/TelemetryManager.gd` |
| **C-4** | Static vs Stateful Service | **Low** | `TelemetryManager` declares instance state (`current_session_id`, `events_buffer`), but all methods are `static` and mint throwaway UUIDs per record rather than utilizing session state. | `src/systems/TelemetryManager.gd:10-24` |

---

## 4. Scalability Findings (Ranked by Severity)

| ID | Concern | Severity | Trigger Volume | Defect Summary | Location |
|---|---|---|---|---|---|
| **S-1** | Synthetic vs Real Contamination | **Critical** | Day 1 / Sample gen | `generate_community_sample_data` writes directly to `user://cyberstack_telemetry.json`, overwriting actual player data with synthetic samples. | `src/systems/TelemetryManager.gd:86-142` |
| **S-2** | Schema Evolution Fragility | **High** | Client v0.2+ | `TelemetryEvent` has no `schema_version` field and persists `active_factions` / `active_tags` as integer strings (`str(int)`), breaking if enums shift. | `src/data/TelemetryEvent.gd:20-71` |
| **S-3** | Aggregation Complexity | **Medium** | >5,000 runs | `AnalyticsEngine` performs nested `O(content × records)` loops with `.has()` lookups instead of a single-pass `O(records + content)` frequency table. | `src/tools/AnalyticsEngine.gd:37-137` |
| **S-4** | Monolithic File Rewrites | **Medium** | >1,000 runs | `TelemetryManager.save_records` parses and rewrites the entire JSON file synchronously on the main thread at run completion. | `src/systems/TelemetryManager.gd:47-60` |
| **S-5** | Hardcoded District Boundaries | **Low** | District count > 4 | `AnalyticsEngine.compute_mortality_curve` hardcodes `{1: 0, 2: 0, 3: 0, 4: 0}` and clamps `r.district_index` to 4, breaking when endless or multi-district runs expand. | `src/tools/AnalyticsEngine.gd:141-162` |

---

## 5. Telemetry Pipeline Status (Scorecard)

| Dimension | Status | Notes & Gaps |
|---|---|---|
| **Run-End Coverage** | ⚠️ Partial | `RUN_END` is recorded on combat win/loss, but **NOT** on `GameManager.abandon_run()`. Ragequits and softlock abandons vanish from mortality data. |
| **In-Run Action Coverage** | ❌ None | Zero telemetry events for shop rerolls, augment slotting/swapping, unit purchases, tactical grid repositioning, or narrative event choices. |
| **Synthetic vs Real Separation** | ❌ Failing | Real and synthetic data share `user://cyberstack_telemetry.json` with no `is_synthetic` discriminator. `ExportTelemetryReport` generates 50 fake runs if <10 records exist. |
| **Data Authenticity** | ⚠️ Compromised | `TelemetryManager.record_run_summary` fabricates `duration_seconds` using `randf_range(180.0, 720.0)` when `duration` is missing from summary. |
| **Schema Soundness** | ⚠️ Fragile | Missing `schema_version`. Enum keys serialized as raw integers. No generic `properties: Dictionary` extension payload. |
| **Privacy & Sanitization** | ✅ Clean | No PII, machine names, OS details, or raw absolute file paths leave the local machine. |
| **Reporting Path** | ⚠️ Local Only | `ExportTelemetryReport` writes markdown to `res://data/community_analytics_report.md`. No export zip bundle or opt-in telemetry sync path exists for distributed players. |

---

## 6. Automation Opportunities

1. **Active Run Save/Load Round-Trip Gate (`tests/test_save_system.gd`)**
   - *Rule:* Assert that saving and loading an active run preserves `star_level >= 2`, specific `tactical_grid` slot assignments (`0..5`), active shop freeze state, and custom drawn `run_districts`.
2. **Telemetry Real/Synthetic Isolation Gate (`tests/test_telemetry_analytics.gd`)**
   - *Rule:* Assert that `generate_community_sample_data()` writes strictly to a dedicated sample path (e.g. `user://cyberstack_sample_telemetry.json`) and flags all events with `is_synthetic = true`.
3. **Enum Key Serialization Guard (`tests/test_telemetry_analytics.gd`)**
   - *Rule:* Ensure `TelemetryEvent.to_dict()` serializes enum keys using stable string names (`Enums.faction_to_string`, `Enums.tag_to_string`) rather than integer indices.
4. **Data Integrity Script in CI (`src/tools/DataValidator.gd`)**
   - *Rule:* Run `DataValidator.gd` headlessly as a mandatory pre-commit or CI check.

---

## 7. What to Keep

- **Data-Driven `.tres` Repository Architecture:** All 63 units, 20 augments, 23 districts, and 13 narrative events are clean Godot resources loaded and cached centrally via `DataRepository.gd`.
- **Standardized Ability & Stat Formatting:** Enums and resource helper methods (`get_stat_lines()`, `get_proc_fragment()`, `get_directional_header()`) provide reliable string generation backed by comprehensive golden-table regression tests (`tests/test_description_formatting.gd`).
- **Tactical Grid Coordinate Helpers:** `UnitInstance.slot_to_coords` and `coords_to_slot` provide clean mathematical abstractions between 1D slot arrays (`0..5`) and 2D grid coordinates (`row, col`).
- **Comprehensive Headless Test Runner:** Fast, headless execution of 20 test suites across systems, UI dimensions, and simulation balances.

---

## 8. Findings Appendix

### Finding F-1: Active Run Save/Load Drops Tactical Grid Layout, Star Level, and District Sequence
- **What:** `SaveManager.save_active_run` omits `star_level`, `grid_slot`, and `run_districts`.
- **Where:** [SaveManager.gd:54-64](file:///C:/dev/cyberstack/src/systems/SaveManager.gd#L54-L64), [SaveManager.gd:103-108](file:///C:/dev/cyberstack/src/systems/SaveManager.gd#L103-L108), [SaveManager.gd:127-159](file:///C:/dev/cyberstack/src/systems/SaveManager.gd#L127-L159)
- **Why it matters:** Players resuming a suspended run lose unit star upgrades, have units removed from the tactical grid on next sync, and lose the randomized district order.
- **Recommended fix:** Update `SaveManager._serialize_units` to store `star_level` and `grid_slot`. In `load_active_run`, place units directly onto `crew_mgr.tactical_grid[grid_slot]`. Serialize `run_districts` array of district IDs.
- **Automation:** Add test assertions in `tests/test_save_system.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-2: Community Sample Data Overwrites Real Player Telemetry
- **What:** `generate_community_sample_data` writes by default to `TELEMETRY_PATH` without separating synthetic records from real player data.
- **Where:** [TelemetryManager.gd:86-142](file:///C:/dev/cyberstack/src/systems/TelemetryManager.gd#L86-L142), [ExportTelemetryReport.gd:18-20](file:///C:/dev/cyberstack/src/tools/ExportTelemetryReport.gd#L18-L20)
- **Why it matters:** Running an export or generating test data destroys or pollutes real player telemetry records.
- **Recommended fix:** Point `generate_community_sample_data` to a separate `SAMPLE_TELEMETRY_PATH` (`user://cyberstack_sample_telemetry.json`) and add `is_synthetic: bool = false` to `TelemetryEvent`.
- **Automation:** Test assertion in `tests/test_telemetry_analytics.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-3: Abandoned Runs Produce Zero Telemetry
- **What:** `GameManager.abandon_run()` does not invoke `TelemetryManager.record_run_summary()`.
- **Where:** [GameManager.gd:128-153](file:///C:/dev/cyberstack/src/core/GameManager.gd#L128-L153)
- **Why it matters:** Skews win rate statistics and blinds analytics to early-run frustration and quit points.
- **Recommended fix:** Call `TelemetryManager.record_run_summary(last_run_summary, active_run_manager.crew_mgr.fielded_units)` in `GameManager.abandon_run()`.
- **Automation:** Unit test in `tests/test_game_manager.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-4: Unversioned Telemetry Schema & Fragile Enum Persistence
- **What:** `TelemetryEvent` lacks a schema version and encodes enum dictionaries using raw integer string keys (`"0"`, `"1"`).
- **Where:** [TelemetryEvent.gd:20-42](file:///C:/dev/cyberstack/src/data/TelemetryEvent.gd#L20-L42), [TelemetryEvent.gd:44-71](file:///C:/dev/cyberstack/src/data/TelemetryEvent.gd#L44-L71)
- **Why it matters:** Reordering or expanding `Enums.Faction` or `Enums.AugmentTag` silently scrambles historical analytics data.
- **Recommended fix:** Add `const SCHEMA_VERSION: int = 1` and map enum keys through `Enums.faction_to_string` / `Enums.tag_to_string` during serialization.
- **Automation:** Unit test in `tests/test_telemetry_analytics.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-5: `PrepScreen._on_unit_sell` Bypasses `ShopManager.sell_unit`
- **What:** `PrepScreen._on_unit_sell` manually calculates unit sell value as flat `base_cost` and deletes units without calling `ShopManager.sell_unit()`.
- **Where:** [PrepScreen.gd:795-805](file:///C:/dev/cyberstack/src/ui/screens/PrepScreen.gd#L795-L805)
- **Why it matters:** Star-level refund scaling (2x for ★2, 4x for ★3) and equipped augment recovery into inventory are bypassed.
- **Recommended fix:** Delegate directly to `shop_mgr.sell_unit(unit, crew_mgr)` and refresh UI.
- **Automation:** UI unit test in `tests/test_ui_dimensions.gd` or `test_crew_manager.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-6: Fabricated Run Duration in Telemetry Records
- **What:** `TelemetryManager.record_run_summary` defaults missing durations to `randf_range(180.0, 720.0)`.
- **Where:** [TelemetryManager.gd:27](file:///C:/dev/cyberstack/src/systems/TelemetryManager.gd#L27)
- **Why it matters:** Distorts average run length KPIs with synthetic random noise.
- **Recommended fix:** Ensure `RunManager` / `GameManager` measures actual elapsed seconds via `Time.get_ticks_msec()` and record actual elapsed duration (or 0.0 if unmeasured).
- **Automation:** Assertion in `tests/test_telemetry_analytics.gd`.
- **Handoff:** None (Pure Engineering).

---

### Finding F-7: Quadratic Aggregation Loops in `AnalyticsEngine`
- **What:** `AnalyticsEngine` iterates `O(units × records)` with inner array scans.
- **Where:** [AnalyticsEngine.gd:37-68, 70-99, 103-137](file:///C:/dev/cyberstack/src/tools/AnalyticsEngine.gd#L37-L137)
- **Why it matters:** At 100k records and 100 content resources, performs >10M search operations per report generation pass.
- **Recommended fix:** Single-pass histogram map: build frequency dictionaries in one loop over `records` in `O(records + content)`.
- **Automation:** Benchmark assertion in `tests/test_telemetry_analytics.gd`.
- **Handoff:** None (Pure Engineering).
