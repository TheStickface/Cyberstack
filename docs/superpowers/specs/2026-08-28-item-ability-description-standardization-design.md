# Standardized Augment & Ability Descriptions — Design

**Date:** 2026-08-28
**Status:** Approved for planning

## Problem

Augment (`AugmentResource`) and operative ability (`UnitResource`) text is inconsistent
and often disconnected from the real mechanical numbers:

- `AugmentResource.description` is pure flavor prose with **zero numbers**. The actual
  numbers live in `stat_modifiers` (`Dictionary[Enums.StatType, float]`), which is not
  consistently rendered anywhere.
- `SynergyTooltip.create_augment_tooltip_node()` has a real bug: the label meant to show
  stats (`stats_label`) is wired to `aug_res.description` instead of `stat_modifiers` — the
  in-game augment hover tooltip currently never shows stats at all.
- Percent-based stats (`ATTACK_SPEED`, `CRIT_CHANCE`, `EVASION` are stored as fractions,
  e.g. `0.20` = 20%) are formatted inconsistently. `AugmentChip._format_stats()` prints the
  raw float (`+ 0.2`) instead of a percent. `BalanceExporter.gd` has the same bug
  (`%.0f` on `0.20` prints `+0`).
- Some flavor numbers no longer match the real data (e.g. `rare_kinetic_rail`'s flavor says
  "+25 bonus damage" while `stat_modifiers` says `+32`).
- Operative `ability_description` (63 unit files) already embeds real numbers, but wrapped
  in full sentences ("Fires a binary logic pulse that deals 130 AP damage and reduces the
  target's armor by 10 for 4s.").

## Goal

Standardize both fields around terse, numeric, stat-first text and fix the rendering code
so every surface (shop cards, tooltips, codex, equipped-slot tooltips) shows the same
consistent format, computed from real data rather than hand-authored prose.

## Out of scope

`UnitResource.bio` (character flavor/identity text) is untouched — it's not a stats field.
Combat mechanics for `trigger_type`/`trigger_effect_id`/`trigger_params` are **not**
implemented anywhere in `CombatBridge` today (confirmed by search) — this work only changes
how the *existing* data is displayed, it does not implement new combat behavior. It *does*
populate `trigger_params` on the 5 proc augments that have a magnitude (previously `{}`
everywhere), but purely as the display source of truth — no code reads it for combat yet.
Whoever implements proc combat later inherits authoritative numbers instead of having to
re-derive them from prose.

## Format Rules

### Augments

- **Stat-only augments** (`trigger_type == PASSIVE_STAT`, currently all 8 Commons + 5
  Rares): `description` becomes `""`. Tooltip/card shows only a `STATS` block built from
  `stat_modifiers`.
- **Proc augments** (7 Rares/Legendaries with a real `trigger_type`): `description` becomes
  a terse effect fragment (no connecting prose, ≤ 8 words), paired with a bold trigger
  header derived from `Enums.trigger_to_string(trigger_type).to_upper()`. Two Legendaries
  (`kinetic_destroyer`, `neural_hive`) have no numeric magnitude anywhere in the source data
  (and `trigger_params` is `{}` on every augment before this change) — their fragments stay
  qualitative rather than inventing new balance numbers. The other 5 proc augments get
  `trigger_params` populated as the fragment's source of truth (next subsection).
- Stat line format: `"<+/-><value><%> <Stat Name>"`, e.g. `+12 Attack Damage`,
  `+20% Attack Speed`. Percent stats: `ATTACK_SPEED`, `CRIT_CHANCE`, `EVASION`.

#### Proc fragments must not become the next drift source

The stat lines are derived from `stat_modifiers`, so they can't rot. The proc fragments
are still hand-authored, and the magnitudes in them (`20%` armor pierce, `15` mana drain,
`40%` armor melt, `15%`/`2s` for `viral_cascade`) have **no backing field** —
`trigger_params` is `{}` on every augment. That is exactly the class of bug this spec
exists to kill (`rare_kinetic_rail` flavor said `+25` while data said `+32`), just moved
from stat prose to proc prose.

This spec's fix: for the 5 proc augments that *do* have a magnitude, populate
`trigger_params` now as the authoritative source, even though `CombatBridge` does not read
it yet:

| id | `trigger_params` |
|---|---|
| rare_kinetic_rail | `{ "armor_pierce_pct": 0.20 }` |
| rare_neural_daemon | `{ "mana_drain": 15 }` |
| rare_viral_cascade | `{ "attack_speed_pct": 0.15, "duration": 2.0 }` |
| legendary_thermal_supernova | `{ "armor_melt_pct": 0.40 }` |
| legendary_viral_pandemic | `{ "enemy_attack_speed_pct": -0.25 }` |

`AugmentResource.get_proc_fragment()` (new, see Code Changes #2) formats the fragment
from `trigger_params` when the keys are present, and falls back to the literal
`description` string otherwise (covers the two qualitative Legendaries, whose
`description` carries no numeric token — the drift check below passes vacuously for them).

**`get_proc_fragment()` output templates** — one entry per `trigger_params` key, matched
in this order; `{pct}` = `round(value * 100)`, `{n}` / `{dur}` = the raw value with any
trailing `.0` trimmed:

| key(s) present | template | result |
|---|---|---|
| `armor_pierce_pct` | `Pierce {pct}% target armor` | `Pierce 20% target armor` |
| `armor_melt_pct` | `Melt {pct}% target armor` | `Melt 40% target armor` |
| `mana_drain` | `Drain {n} mana from enemy` | `Drain 15 mana from enemy` |
| `attack_speed_pct` + `duration` | `+{pct}% Attack Speed for {dur}s` | `+15% Attack Speed for 2s` |
| `enemy_attack_speed_pct` | `{pct}% enemy Attack Speed` (sign always shown) | `-25% enemy Attack Speed` |
| none matched | literal `description` verbatim | `Burst damage to nearby enemies` |

These templates reproduce the `new description` column of the mapping table exactly — that
table is the golden expectation for `get_proc_fragment()` (see Testing). `rare_viral_cascade`
is the one fragment that keeps a connective ("for") and a leading `+`, because it *is* a
timed stat buff and reads wrong without them; it is the explicit exception to the
"no connecting prose" rule. Its `+15%` proc magnitude is deliberately distinct from its
`+12% Attack Speed` passive stat line (different mechanic, different value) — surfaces label
one under `STATS` and the other under the proc header so they don't read as a contradiction.

A unit test asserts that every numeric token appearing in a proc `description` also appears
in that augment's `trigger_params` (augments whose `description` has no numeric token are
exempt) — so the two can never silently diverge again.

Full mapping for all 20 augments (stat lines are derived automatically from existing
`stat_modifiers` — listed here for review, not hand-entered):

| id | new `description` | proc header | stat lines (unchanged data, shown for reference) |
|---|---|---|---|
| common_kinetic_accelerator | `""` | — | +12 Attack Damage |
| common_kinetic_plating | `""` | — | +100 Max Health, +8 Armor |
| common_neural_buffer | `""` | — | +60 Shield, +25 Starting Mana |
| common_neural_link | `""` | — | +15 Ability Power, +15 Starting Mana |
| common_thermal_blaster | `""` | — | +14 Attack Damage, +10 Ability Power |
| common_thermal_core | `""` | — | +120 Max Health, +5 Armor |
| common_viral_nanites | `""` | — | +8% Attack Speed |
| common_viral_spores | `""` | — | +140 Max Health, +8% Evasion |
| rare_kinetic_overdrive | `""` | — | +20% Attack Speed, +12 Armor |
| rare_neural_synapse | `""` | — | +35 Ability Power, +15% Attack Speed |
| rare_thermal_exhaust | `""` | — | +10 Armor, +150 Shield |
| rare_thermal_laser | `""` | — | +28 Ability Power, +15% Attack Speed |
| rare_viral_siphon | `""` | — | +22 Attack Damage, +15% Attack Speed |
| rare_kinetic_rail | `Pierce 20% target armor` | ON ATTACK | +32 Attack Damage, +15% Crit Chance |
| rare_neural_daemon | `Drain 15 mana from enemy` | ON ATTACK | +30 Ability Power, +20 Starting Mana |
| rare_viral_cascade | `+15% Attack Speed for 2s` | ON ALLY TAG TRIGGER | +12% Attack Speed |
| legendary_kinetic_destroyer | `Burst damage to nearby enemies` | ON KILL | +45 Attack Damage, +15% Crit Chance |
| legendary_neural_hive | `Share mana pool, trigger crew-wide` | ON ABILITY CAST | +50 Ability Power, +30 Starting Mana |
| legendary_thermal_supernova | `Melt 40% target armor` | ON ABILITY CAST | +60 Ability Power |
| legendary_viral_pandemic | `-25% enemy Attack Speed` | ON KILL | +40 Ability Power, +30% Attack Speed |

### Operative abilities

`ability_description` (63 unit `.tres` files) is rewritten from a full sentence to
comma-separated numeric fragments — strip the scaffolding verbs/subjects, keep every
number, unit, and duration exactly as authored today. No new balance numbers invented.

#### Style guide (normative — the checkpoint reviews against this, not taste)

- **Fragment separator:** `, ` (comma-space). No trailing period.
- **Order within a fragment:** `<magnitude><unit> <effect noun> <target/AoE qualifier> <duration>`.
  e.g. `240 AP dmg (cone) (2.5s)`.
- **Damage:** `<n> AP dmg` / `<n> AD dmg` / `<n> true dmg`. Never `damage`, never `HP`.
- **Debuffs/reductions** authored as "reduces X by n" → `-<n> <Stat>` (`-10 Armor`).
  Resource drains → `-<n> mana`.
- **Buffs/grants** → `<n> <Stat>` with no sign (`240 Shield`, `300 HP barrier`).
- **Percent effects** → `<n>% <effect>` (`reflects 20% dmg`, `20% armor pierce`).
- **Multi-hit** → `<count>x <per-hit value>` (`3x 140 AP dmg`), never "140 x3" or "420 total".
- **Duration** → trailing `(<n>s)` on the fragment it modifies. Shared duration that
  applies to the whole ability → single trailing `(<n>s)` on the last fragment.
- **Targeting / AoE qualifiers** (parenthesised, lower-case): `(self)`, `(allies)`,
  `(cone)`, `(nearby)`, `(lowest-HP target)`, `(adjacent)`. Bare `self` / `allies` only
  when the sentence used them as the grant target of a preceding value
  (`240 Shield self`).
- **Status effects with no number** keep a bare verb + scope: `blind nearby (2.5s)`,
  `stun target (1s)`.
- Target casing: `AP`, `AD`, `HP`, `s` for seconds; everything else sentence-case stat
  names via `Enums.stat_to_string()` spelling.

Note the deliberate split from augment stat lines: abilities use compact combat shorthand
(`130 AP dmg`) for a one-shot damage instance, augments use the full stat name
(`+15 Ability Power`) for a persistent stat bonus. Same underlying stat, different notation
because they're different things — this is a decision, not an inconsistency to "fix" later.

#### Numeric-preservation test (covers all 63 files mechanically)

Add a unit test that, for every unit `.tres`, extracts the ordered multiset of numeric
tokens (regex `\d+(?:\.\d+)?%?` plus a trailing `s` for durations) from the **pre-change**
`ability_description` (captured as a fixture map `unit_id -> old_string` committed with the
change) and asserts every token still appears in the new `ability_description`. This turns
"keep every number/unit exactly" from a manual promise into a build-enforced invariant, and
is the real coverage for the 57 files not worked out longhand in this spec. The checkpoint
review then only has to judge *wording*, not hunt for dropped numbers.

Worked examples (from real data):

| unit | old | new |
|---|---|---|
| ai_bastion | `Projects an encrypted dome providing 240 Shield to itself and 100 Shield to adjacent allies for 4s.` | `240 Shield self, 100 Shield allies (4s)` |
| ai_byte | `Fires a binary logic pulse that deals 130 AP damage and reduces the target's armor by 10 for 4s.` | `130 AP dmg, -10 Armor (4s)` |
| ai_cipher | `Fires 3 laser bursts that prioritize the lowest-health enemy for 140 AP damage each.` | `3x 140 AP dmg (lowest-HP target)` |
| ai_dreadnought | `Vents superheated coolant in a 360-degree cone, dealing 240 AP damage and blinding nearby enemies for 2.5s.` | `240 AP dmg (cone), blind nearby (2.5s)` |
| ai_glitch | `Detonates digital logic bomb dealing 180 AP damage and draining 30 mana from targets.` | `180 AP dmg, -30 mana` |
| ai_null_construct | `Creates a 300 HP refractive barrier absorbing incoming damage and reflecting 20% back to attackers.` | `300 HP barrier, reflects 20% dmg` |

The remaining 57 unit files get the same mechanical treatment during implementation
(read existing sentence → apply the style guide above → keep every number/unit → drop
connective prose → join with commas). The numeric-preservation test above guards the
"keep every number" half automatically; the implementation checkpoint reviews only wording
against the style guide.

## Code Changes

1. **`src/core/Enums.gd`** — add:
   - `static func is_percent_stat(stat: StatType) -> bool` (true for `ATTACK_SPEED`,
     `CRIT_CHANCE`, `EVASION`)
   - `static func format_stat_value(stat: StatType, value: float) -> String` → `"+12"` or
     `"+20%"` (sign always shown, percent stats multiply by 100). Value is rounded to the
     nearest integer after the ×100; `0` still renders with a sign (`"+0"`) but no augment
     data currently hits that case.
   - `static func trigger_to_string(t: TriggerType) -> String` — **this helper does not
     exist today** (only `stat_to_string` does). Explicit `match` mapping, not string
     munging of `TriggerType.keys()`:

     | enum value | returns |
     |---|---|
     | `PASSIVE_STAT` | `""` |
     | `ON_COMBAT_START` | `"On Combat Start"` |
     | `ON_ATTACK` | `"On Attack"` |
     | `ON_HIT` | `"On Hit"` |
     | `ON_KILL` | `"On Kill"` |
     | `ON_ABILITY_CAST` | `"On Ability Cast"` |
     | `ON_ALLY_TAG_TRIGGER` | `"On Ally Tag Trigger"` |
     | `ON_DAMAGE_TAKEN` | `"On Damage Taken"` |
     | `ON_HEALTH_BELOW_THRESHOLD` | `"On Health Below Threshold"` |
     | `_` (fallback) | `"Trigger"` |

     Callers apply `.to_upper()` for the header (`"ON ATTACK"`); the plain-case string is
     kept for any future non-header use. The proc-header cells in the augment mapping table
     above are exactly `trigger_to_string(...).to_upper()`.

2. **`src/data/resources/AugmentResource.gd`** — add:
   - `func get_stat_lines() -> Array[String]` → e.g. `["+12 Attack Damage", "+15% Crit Chance"]`,
     using `Enums.format_stat_value()` + `Enums.stat_to_string()`. **Canonical order**, not
     `stat_modifiers` insertion order (which is per-`.tres` authoring order and would make
     cards inconsistent): sort by `StatType` enum ordinal, so every surface lists the same
     augment's stats identically.
   - `func has_proc() -> bool` → `trigger_type != Enums.TriggerType.PASSIVE_STAT`
   - `func get_proc_header() -> String` → `Enums.trigger_to_string(trigger_type).to_upper()`
     if `has_proc()`, else `""`
   - `func get_proc_fragment() -> String` → formatted from `trigger_params` when the known
     keys are present (see "Proc fragments must not become the next drift source"), else the
     literal `description` string. Empty when `has_proc()` is false.

3. **Display code** — replace direct `aug.description` stat-block rendering with the new
   helpers. Two layouts, chosen per surface by how much room it has:

   **Full block** — hover tooltips and the Codex, which can grow vertically:
   ```
   STATS
   +12 Attack Damage
   +15% Crit Chance

   ON ATTACK
   Pierce 20% target armor
   ```
   (`ON ...` section omitted entirely when `has_proc()` is false.)

   **Compact line** — the small fixed widgets (`AugmentChip`, `ShopSlotCard` augment
   branch): stat lines only, joined with `  ·  `, no `STATS` header, no proc block. A proc
   augment adds a trailing `⚡` glyph (or the existing proc indicator if the card already
   has one) so the player knows to hover for the effect. No wrapping — the container
   already clips; if the joined string overflows, that's the same behaviour as today's
   flavor text and is acceptable (the tooltip carries the full detail).

   | surface | file / entry point | layout |
   |---|---|---|
   | augment chip | `src/ui/components/AugmentChip.gd` (`_update_ui()`, `_format_stats()`) | compact line |
   | shop card | `src/ui/components/ShopSlotCard.gd` (augment branch of `_update_ui`/setup) | compact line |
   | synergy tooltip | `src/ui/components/SynergyTooltip.gd` (`create_augment_tooltip_node()`) | full block — also **fixes the `stats_label` bug**: `stats_label` ← `get_stat_lines()`, proc section ← `get_proc_header()` / `get_proc_fragment()` |
   | codex | `src/ui/screens/CodexScreen.gd` (`_populate_augments()`) | full block |
   | equipped-slot tooltip | `src/ui/components/OperativeCard.gd` `_refresh_slots()` (currently `slot_btn.tooltip_text = "%s\nDrag to swap/move…" % aug.description`, ~line 358) | full block as **plain newline-joined text** — this is a `tooltip_text` string, not a rich node: headers on their own lines, blank line before the proc section, keep the trailing `Drag to swap/move or right-click to unequip` hint |

4. **`src/tools/BalanceExporter.gd`** — reuse `Enums.format_stat_value()` in the augment
   and synergy-bonus markdown tables, fixing the same percent-formatting bug incidentally.

## Testing

- Existing test suite has no assertions on exact `description`/tooltip string content
  (confirmed via search) — no existing tests need updating for content changes.
- Add unit coverage for the new `Enums.format_stat_value()` / `is_percent_stat()` /
  `trigger_to_string()` and `AugmentResource.get_stat_lines()` / `get_proc_header()` /
  `get_proc_fragment()` (flat stat, percent stat, negative modifier, passive vs. proc
  augment, canonical stat ordering, `trigger_params`-derived vs literal-fallback fragment).
- `trigger_to_string()`: assert every `TriggerType` enum value returns a non-empty label
  except `PASSIVE_STAT` — a table-driven test over `TriggerType.values()` so a future enum
  addition fails the suite instead of silently hitting the `_` fallback.
- **Augment golden test** — the "Full mapping for all 20 augments" table is the acceptance
  criterion, not just documentation. Encode it as a fixture (`id → {description,
  proc_header, stat_lines}`) and, for every augment `.tres`, assert
  `get_proc_fragment() == description`, `get_proc_header() == proc_header`, and
  `get_stat_lines()` joins to the `stat lines` cell exactly (locks formatting, sign,
  percent conversion, **and** canonical ordering in one check). A new or reordered
  `stat_modifiers` entry that isn't reflected in the spec table fails here.
- **Ability golden test** — the 6 worked examples become direct
  `ability_description == "<new>"` assertions on those 6 `.tres` after the rewrite.
- Numeric-preservation test over all 63 unit `.tres` (see "Operative abilities"): fixture
  map of pre-change `ability_description`, assert every numeric token survives the rewrite.
- Proc-drift test: for every proc augment, every numeric token in `description` must also
  appear in `trigger_params` (proc augments whose `description` has no numeric token are
  exempt — covers `kinetic_destroyer` / `neural_hive`).
- Manual spot-check: launch the game (or `/run`) and (a) hover a Common, a proc Rare, and a
  Legendary augment in the **shop** to confirm the compact stat line + proc glyph, (b) open
  each of their **full-block** tooltips, (c) check an operative's **equipped-slot** hover,
  and (d) the Codex augment tab.

## Risk / Rollback

Purely additive helper methods + data/text content changes + swapping which string a label
renders. The only new *data* is `trigger_params` values on 5 augment resources — no new
fields, no schema change, and nothing reads them for behavior yet. No save-data format
changes (these are static content resources, not save state), so this is low risk and
trivially revertable via git if needed.
