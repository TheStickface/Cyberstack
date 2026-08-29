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
how the *existing* data is displayed, it does not implement new combat behavior.

## Format Rules

### Augments

- **Stat-only augments** (`trigger_type == PASSIVE_STAT`, currently all 8 Commons + 5
  Rares): `description` becomes `""`. Tooltip/card shows only a `STATS` block built from
  `stat_modifiers`.
- **Proc augments** (7 Rares/Legendaries with a real `trigger_type`): `description` becomes
  a terse effect fragment (no connecting prose, ≤ 8 words), paired with a bold trigger
  header derived from `Enums.trigger_to_string(trigger_type).to_upper()`. Two Legendaries
  (`kinetic_destroyer`, `neural_hive`) have no numeric magnitude anywhere in the source data
  or `trigger_params` (which is empty on every augment) — their fragments stay qualitative
  rather than inventing new balance numbers.
- Stat line format: `"<+/-><value><%> <Stat Name>"`, e.g. `+12 Attack Damage`,
  `+20% Attack Speed`. Percent stats: `ATTACK_SPEED`, `CRIT_CHANCE`, `EVASION`.

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
(read existing sentence → keep every number/unit → drop connective prose → join with
commas). This is reviewed at the implementation checkpoint before being considered done,
since 63 files is too many to hand-verify in this spec.

## Code Changes

1. **`src/core/Enums.gd`** — add:
   - `static func is_percent_stat(stat: StatType) -> bool` (true for `ATTACK_SPEED`,
     `CRIT_CHANCE`, `EVASION`)
   - `static func format_stat_value(stat: StatType, value: float) -> String` → `"+12"` or
     `"+20%"` (sign always shown, percent stats multiply by 100)

2. **`src/data/resources/AugmentResource.gd`** — add:
   - `func get_stat_lines() -> Array[String]` → e.g. `["+12 Attack Damage", "+15% Crit Chance"]`,
     using `Enums.format_stat_value()` + `Enums.stat_to_string()`
   - `func has_proc() -> bool` → `trigger_type != Enums.TriggerType.PASSIVE_STAT`
   - `func get_proc_header() -> String` → `Enums.trigger_to_string(trigger_type).to_upper()`
     if `has_proc()`, else `""`

3. **Display code** — replace direct `aug.description` stat-block rendering with the new
   helpers in:
   - `src/ui/components/AugmentChip.gd` (`_update_ui()`, `_format_stats()`)
   - `src/ui/components/SynergyTooltip.gd` (`create_augment_tooltip_node()` — fixes the
     `stats_label` bug)
   - `src/ui/components/ShopSlotCard.gd` (augment branch of `_update_ui`/setup)
   - `src/ui/screens/CodexScreen.gd` (`_populate_augments()`)
   - `src/ui/components/OperativeCard.gd` (equipped-slot tooltip, line ~259)

   Standard block layout used everywhere:
   ```
   STATS
   +12 Attack Damage
   +15% Crit Chance

   ON ATTACK
   Pierce 20% target armor
   ```
   (`ON ...` section omitted entirely when `has_proc()` is false.)

4. **`src/tools/BalanceExporter.gd`** — reuse `Enums.format_stat_value()` in the augment
   and synergy-bonus markdown tables, fixing the same percent-formatting bug incidentally.

## Testing

- Existing test suite has no assertions on exact `description`/tooltip string content
  (confirmed via search) — no existing tests need updating for content changes.
- Add unit coverage for the new `Enums.format_stat_value()` / `is_percent_stat()` and
  `AugmentResource.get_stat_lines()` / `get_proc_header()` (flat stat, percent stat,
  negative modifier, passive vs. proc augment).
- Manual spot-check: launch the game (or `/run`) and hover a Common, a proc Rare, and a
  Legendary augment to confirm the tooltip renders the new block correctly, and check the
  Codex augment tab.

## Risk / Rollback

Purely additive helper methods + data/text content changes + swapping which string a label
renders. No schema changes, no save-data format changes (these are static content
resources, not save state), so this is low risk and trivially revertable via git if needed.
