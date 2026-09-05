# Async PvP — Feasibility Evaluation & Theoretical Implementation Plan

**Date:** 2026-09-04
**Status:** Evaluation / not approved for implementation
**Scope:** Can Cyberstack support an asynchronous PvP mode (players' crews fight other players' saved crews on certain stages, alongside PvE), and what should be built early so the option stays open.

---

## 1. Verdict

**Feasibility: 7 / 10.**

The game-state layer is already in good shape for async PvP: crews are pure data keyed by string ids, JSON serialization exists, systems are `RefCounted` and don't need the scene tree, and a headless combat resolver already runs in CI. Nothing in the data model or run loop blocks the mode.

What holds the score below 8 is the **combat engine**. Cyberstack currently has two independent combat implementations that disagree with each other, neither is deterministic, and both treat the enemy side as a fundamentally different kind of thing from the player side. Async PvP requires exactly one engine, seeded, fixed-step, and symmetric. That is a real refactor, but it is one the project should do anyway because the balance simulator and the shipped arena currently simulate different games.

What holds it below 9–10 is everything outside the repo: there is no identity, no backend, no anti-cheat story. That is ordinary work, not a design blocker, and it can be deferred entirely.

**Bottom line:** build the five "early mechanisms" in Section 5 now (roughly a week of focused work, most of it paying off for PvE balance regardless), and the decision on whether to actually ship PvP can be made later at low cost.

---

## 2. What "async PvP" means here

The recommended model is **ghost defense** (The Bazaar / Clash Royale style):

- When a player locks in a crew before a fight at stage *S* (e.g. `2-1`), the game captures a **snapshot** of that crew: units, star levels, augments, grid placement, unlocked slots, doctrines, conduits.
- Snapshots are uploaded to a pool keyed by stage and a power band.
- Certain encounter nodes become **PVP nodes**. Instead of `CombatBridge._generate_enemy_squad()`, the enemy is another player's snapshot from the same stage.
- Combat resolves locally on the attacker's machine from a seed. The result (plus seed and both snapshot hashes) is reported. The defender is never online.
- The defender later sees "your `2-1` crew was attacked 14 times, won 9" and can watch replays.

No live matchmaking, no lockstep networking, no shared shop. The economy and run loop stay untouched. This is the only PvP shape worth considering for a singleplayer roguelite; anything synchronous is a 2–3/10.

---

## 3. System-by-system evaluation

### 3.1 Data model — **ready (9/10)**

| Component | Finding |
|---|---|
| `UnitInstance` | Pure `RefCounted`; state is `unit_resource.id`, `level`, `star_level`, `grid_slot`, `equipped_augments[3]`. Trivially serializable. |
| `UnitResource`, `AugmentResource`, `ConduitResource`, `DistrictResource` | Content resources addressed by string `id` through `DataRepository`. A snapshot only needs ids. |
| `SynergyReport` | Fully derived from the crew via `SynergyEngine.evaluate_crew()`. Doesn't need to be stored; recompute from the snapshot. |
| `CrewManager.calculate_formation_bonuses()` | Derived from grid + doctrines + conduits. Also recomputable. |

Gap: `UnitInstance.instance_id` is a random `ResourceUID`/`randi()`. Fine locally, but a snapshot must assign stable ids (slot index is enough).

### 3.2 Serialization — **mostly ready (7/10)**

`SaveManager.save_active_run()` already serializes units, augments, and grid slots to JSON with a `schema_version`.

Gaps that matter for a defender snapshot:

- `CrewManager.unlocked_slots`, `slot_specializations` (doctrines), and `slot_conduits` are **not** serialized. A resumed run silently loses doctrines and conduits today. A PvP snapshot needs all three.
- Conduit remaining durations are not serialized.
- No content version hash. If `common_kinetic_plating.tres` is rebalanced, every stored ghost changes strength silently.

### 3.3 Combat resolution — **the blocker (4/10)**

There are two engines:

| | `CombatMockArena.gd` (shipped) | `BalanceSimulator.simulate_single_battle()` (CI / balance) |
|---|---|---|
| Timestep | Variable `_process(delta)` × speed multiplier; Skip button calls `_process(0.2)` | Fixed `dt = 0.1`, 60 s cap |
| RNG | Global `randf()` / `randi()` | Global `randf()` / `randi()` |
| Synergy report | **Never read.** Payload carries `player_synergies` but the arena ignores it | Applied to player side |
| Formation bonuses | Applied to player only | Applied to player only |
| District hazards | None | `_apply_district_environmental_hazards()` |
| Enemy scaling | `DISTRICT_ENEMY_SCALING` + boss ×1.35 HP / ×1.20 AD baked into combatant creation | Its own version inside `_create_combatant()` |
| Runs headless | No (Control node, needs scene tree) | Yes |

Consequences for PvP:

1. **Non-deterministic.** Same two crews produce different results on every run, and the Skip button changes the outcome because it changes `dt`. A result cannot be reproduced, verified, or replayed.
2. **Asymmetric.** The enemy side gets district multipliers and no synergies / formations / conduits. A defender snapshot dropped into either engine would be fighting with a different ruleset than it was built under.
3. **Two sources of truth.** Whatever engine resolves PvP, the other one will disagree, so either the balance sim or the visual arena is lying.

This is the one place the current architecture actively works against PvP. It is also a pre-existing PvE problem: the balance reports in `data/` are generated by an engine that ignores what the player actually experiences in the arena.

### 3.4 Run loop / stage structure — **ready (8/10)**

- `RunManager` drives a fixed node sequence per subdistrict from `DistrictResource.subdistrict_N_sequence`, typed by `Enums.EncounterType`.
- Adding `EncounterType.PVP` and letting a district's sequence include it is a small, local change. `GameManager.start_combat_encounter()` already branches on `is_boss`; a `pvp` branch fits the same shape.
- `Constants.format_stage()` gives a canonical stage key (`"2-1"`) to bucket defenders by.
- Fallback is free: if no defender exists for a stage/band, call the existing PvE generator. The mode degrades gracefully offline.

### 3.5 Player identity & meta — **absent but simple (5/10)**

`MetaProfile` has no player id, no display name, no rating. Needs a device-generated UUID at minimum. Nothing else in the profile conflicts.

### 3.6 Networking / backend — **absent (n/a)**

The project is fully offline. Godot 4.6 ships `HTTPRequest`, which is all a ghost-defense backend needs (three endpoints, see Section 6). No Godot multiplayer API is required.

### 3.7 Headless execution — **ready (9/10)**

`Run_Tests.bat` already runs `godot --headless -s tests/test_runner.gd`, and `BalanceSimulator` runs whole runs headless. A server-side verifier is the same binary with a different entry script.

### 3.8 Telemetry — **ready (8/10)**

`TelemetryManager` already records per-run crews as JSON records with a session id. A `BattleRecord` is the same shape with a seed and two crew snapshots. `MetricsDashboard` / `AnalyticsEngine` can consume PvP records with minor extension.

---

## 4. Scoring summary

| Area | Score | Blocks PvP? |
|---|---|---|
| Data model | 9 | No |
| Serialization | 7 | Minor gaps |
| Combat engine | 4 | **Yes** — must unify, seed, fix-step, symmetrize |
| Run loop / stages | 8 | No |
| Identity / meta | 5 | Easy add |
| Backend | – | External work, deferrable |
| Headless | 9 | No |
| Telemetry | 8 | No |
| **Overall** | **7** | |

---

## 5. Mechanisms to build early (regardless of whether PvP ships)

These are ordered by how much more expensive they get the longer they wait. Each one also improves PvE.

### 5.1 Single headless `CombatEngine`

Extract the simulation out of `CombatMockArena.gd` into `src/systems/CombatEngine.gd` (`RefCounted`):

```
CombatEngine.new(payload: Dictionary, rng: RandomNumberGenerator)
  .tick(dt: float) -> Array[CombatEvent]      # fixed dt, returns events for rendering
  .is_resolved() -> bool
  .result() -> Dictionary                      # victory, duration, survivors, hp fractions
  .run_to_completion() -> Dictionary           # for sim / verifier
```

- `CombatMockArena` becomes a **renderer**: it accumulates real `delta`, calls `tick(FIXED_DT)` in a loop, and animates the returned events. Speed and Skip only change how many ticks run per frame.
- `BalanceSimulator.simulate_single_battle()` calls `run_to_completion()` and deletes its private copy of `_step_combatant`, `_apply_damage`, `_apply_sim_formations`, `_apply_district_environmental_hazards`.
- Ability logic, retaliation, targeting, hazards all live in one place.

This is the single most valuable change in this document. Without it, PvE balance is being tuned against a simulation the player never plays.

### 5.2 Seeded RNG

- `CombatEngine` takes a `RandomNumberGenerator` and uses **only** that instance. No `randf()` / `randi()` inside combat.
- `CombatBridge.package_combat_payload()` generates and stores `combat_seed` in the payload (64-bit int).
- Test: two engines with the same payload and seed must produce identical event streams and results. This test also catches any future accidental global-RNG use.

### 5.3 Fixed timestep

- `Constants.COMBAT_TICK_DT = 0.1` (or 1/30). The engine never sees wall-clock time.
- Hazards, ICDs, attack timers, mana all advance per tick.

### 5.4 Symmetric squad payload

Replace the `player_*` / `enemy_*` halves of the combat payload with two identical `SquadSnapshot` structures:

```
SquadSnapshot {
  units: [ { unit_id, star_level, grid_slot, augment_ids[3] } ],
  unlocked_slots: [0,1,2,4],
  slot_doctrines: { "4": "overwatch_perch" },
  slot_conduits: { "1": { conduit_id, remaining_fights } },
  stat_multipliers: { hp: 1.0, dmg: 1.0 }     # PvE scaling lives HERE, not in the engine
  synergy_report: <derived, not stored>,
  formation_bonuses: <derived, not stored>
}
```

- `CombatBridge` builds the enemy snapshot for PvE by generating units then setting `stat_multipliers` from `DISTRICT_ENEMY_SCALING` and the boss factor.
- The engine applies synergies, formations, conduits, doctrines, and multipliers **to both sides the same way**. Enemies gain formation logic and synergies (currently they get neither), which the balance pass will need to re-tune. That re-tune is itself a benefit: PvE enemies built under the player's rules are the only way a PvP defender can be balanced against PvE.
- `SquadSnapshot.from_crew_manager(cm)` and `to_dict()` / `from_dict(repo)` live next to `SaveManager` and reuse its unit serializers.

### 5.5 Content version hash + `BattleRecord`

- `DataRepository.get_content_hash()` — SHA-256 over sorted `id` + exported fields of every unit/augment/conduit/district. Cheap to compute at load.
- `BattleRecord { schema_version, content_hash, stage, seed, attacker: SquadSnapshot, defender: SquadSnapshot, result }`.
- Every fight (PvE included) can be logged as a `BattleRecord` into telemetry. Replaying a record = constructing the engine from it. This gives the balance team reproducible bug reports for free.

### 5.6 Stable player id

- `MetaProfile.player_id` (UUID, generated once), `display_name`. Serialize via existing `to_dict()`.

### 5.7 Fix the existing save gap

- Serialize `unlocked_slots`, `slot_specializations`, `slot_conduits` in `SaveManager.save_active_run()`. This is a current bug (resumed runs lose doctrines and conduits) and is a prerequisite for 5.4.

---

## 6. Theoretical implementation phases

### Phase 0 — Foundations (no PvP visible to players)

Everything in Section 5. Deliverables:

- `CombatEngine.gd` with determinism test and arena/sim parity test (`tests/test_combat_engine.gd`).
- `SquadSnapshot` round-trip test.
- Balance re-run after enemies gain synergy/formation parity; update `data/balance_*.md`.

Risk: the re-tune of enemy comps. Mitigation: `stat_multipliers` per district can absorb most of it.

### Phase 1 — Local ghost pool (offline PvP)

- `EncounterType.PVP`; allow it in `subdistrict_2_sequence` for at least one district.
- `GhostPool` (`user://cyberstack_ghosts.json`): on every lock-in, append `SquadSnapshot` keyed by stage. Cap per stage.
- `CombatBridge.package_pvp_payload(attacker, defender_snapshot, stage, seed)`.
- PVP node picks a defender from the local pool by stage and a simple power band (total unit cost × star multiplier). Falls back to PvE generation when empty.
- **Shipped ghost pack:** use the uncommitted `StrategyArchetypes.gd` to generate archetype crews per stage and bundle them as `res://data/ghosts/*.json`. Players get PvP-shaped fights on day one with no backend, and the pack doubles as a balance regression suite.
- Arena UI: opponent nameplate, "vs Ghost of <name>" header.

Phase 1 proves the entire loop offline. If PvP is later cut, the ghost pack still ships as a "rival crews" PvE feature.

### Phase 2 — Backend

Minimal service (Cloudflare Worker + KV/D1, Supabase, or any small HTTP host):

| Endpoint | Purpose |
|---|---|
| `POST /snapshots` | `{ player_id, stage, content_hash, snapshot }` — upsert one defender per player per stage |
| `GET /defenders?stage=2-1&band=3&content_hash=…&exclude=player_id` | Return N candidates |
| `POST /battles` | `BattleRecord` with result |

- Client: `PvPClient.gd` wrapping `HTTPRequest`, fully async, never blocks the run. If offline or the request fails, use the local pool.
- Content hash mismatch → server serves only snapshots from the same content version, or the client rejects. Ghosts from old balance versions simply age out.
- Anti-cheat tier 1: server re-runs `BattleRecord` through the same engine in headless Godot (`godot --headless -s tools/verify_battle.gd`). GDScript float math is deterministic on the same binary and architecture; run the verifier on the same build the client uses. Reject results that don't reproduce.

### Phase 3 — Meta layer

- Defender stats on the profile (attacks received, defense win rate), replays of losses (from `BattleRecord`, rendered by the arena).
- Rating per stage or global; power bands become rating bands.
- Revenge attack on a specific defender.
- Weekly ladder / season reset keyed on `content_hash` epochs.

---

## 7. Open design questions (do not block Phase 0)

1. **Where do PVP nodes sit?** One per subdistrict-2 sequence, or a district-level property (`DistrictResource.pvp_enabled`)? Recommendation: a per-district flag plus `EncounterType.PVP`, so themed "arena" districts can be pure PvP and others opt out.
2. **What does the attacker win?** Same payout as a FIGHT node keeps economy untouched. Bonus reputation for beating higher-rated ghosts adds stakes without inflating gold.
3. **What does a defense loss cost the defender?** Recommendation: nothing in-run (their run is over or elsewhere); only rating. Anything that touches an in-progress run breaks the singleplayer contract.
4. **Snapshot moment.** Capture at lock-in (what the player actually fought with) vs. at subdistrict clear (what beat the boss). Lock-in is simpler and gives more snapshots.
5. **Cross-platform float determinism.** If the game ever ships on ARM/mobile alongside x64 desktop, verify the engine agrees across builds before enabling server-side verification, or accept attacker-reported results for a casual mode.

---

## 8. Cost estimate (relative)

| Phase | Effort | Value even without PvP |
|---|---|---|
| 0 — Foundations | ~1 week | High: fixes sim/arena divergence, save bug, gives reproducible battles |
| 1 — Local ghosts + pack | ~3–4 days | Medium: "rival crews" content, balance regression suite |
| 2 — Backend | ~1 week + ops | None |
| 3 — Meta | open-ended | None |

Phase 0 is the recommendation regardless of the PvP decision. Phases 2–3 can wait until the mode is confirmed.
