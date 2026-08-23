# Cyberstack — Game Design Spec
**Date:** 2026-06-20
**Status:** Approved

---

## 1. Core Fantasy & Identity

Cyberstack is a singleplayer roguelite autobattler set in a neon-soaked cyberpunk city. Each run is a job. The player begins as a two-person operation and moves through the city's districts — corporate arcologies, black-market bazaars, underground server vaults — recruiting operatives and gearing them up as the run progresses. Runs end at a final district boss. Death resets the run but feeds into a persistent meta-layer that grows the player's footprint in the city over time.

The core tension is **crew assembly under uncertainty**: the player never knows exactly who they'll have the chance to recruit, so every run demands building around what the run offers rather than defaulting to a fixed optimal comp. Faction synergies and augment tag chains reward players who read what the run is offering and commit to it.

The name *Cyberstack* refers to the act of stacking augments, traits, and crew synergies into a volatile, escalating combination — an in-world term operatives use for a well-optimized loadout.

---

## 2. Run Structure

### Districts
A run consists of **3–4 districts** followed by a **final boss district**. Each district has a thematic identity tied to a city faction and contains a fixed sequence of encounters: roughly 3 fights, 1–2 shops, and 1 optional event node. Encounters within a district are linear. Which districts appear and their order has roguelite variance between runs.

To support replayability, the target is a **pool of ~20 districts** to draw from per run (plus the final boss district), so repeat runs don't see the same sequence. The roster below is split into three tiers of design maturity: the original four core examples, eight thematically-detailed additions that each close a gap in faction/tag/tone coverage, and twelve further concepts to round the pool out to 20 — these last twelve are name/enemy/aesthetic only, with shop and event mechanics intentionally left as placeholders for later design passes.

#### Core district examples
- Corporate Arcology — Corp Enforcer enemies, chrome/white aesthetic, economy-focused events
- Slum Market — Street Runner enemies, cluttered neon aesthetic, recruitment-focused shops
- Server Vault — Rogue AI enemies, deep blue aesthetic, augment-heavy shops
- Black Site — Mixed elite enemies, final district, Legendary augments available

#### Thematically-detailed additions
These were designed to fill specific gaps: the Fixers faction had no home district, three of the four augment tags (`Thermal`, `Neural`, `Kinetic`) had no environmental home, and the roster leaned toward "disciplined economy" tone without a vice/risk counterweight or a lawless-ruins counterweight to Black Site.

- **Contract Row** — Fixers enemies (Info Brokers, Mercenary Contractors), muted grey/amber noir aesthetic (trench-coats, rain-slicked alleys, dead neon signage). Info-focused shop: pay gold to reveal the next district's enemy comp or shop stock before committing.
- **Thermal Foundry** — Foundry Drone / Heat-Sync Merc enemies, molten orange-red aesthetic (steam vents, sparking rail lines). Augment shop weighted toward the `Thermal` tag; optional event is a coolant-leak hazard that punishes slow fights but pays bonus gold for fast ones.
- **Neural Exchange** — Mind Hacker / Neural Leech enemies, violet/electric-blue brainwave-hologram aesthetic. Augment shop weighted toward the `Neural` tag; event is a "memory auction" — pay gold *or* sacrifice a random augment from a benched unit for a guaranteed Rare/Legendary pick.
- **Kinetic Yards** — Scrap Golem / Rail Brawler enemies, rust-and-magnetism industrial-yard aesthetic. Augment shop weighted toward the `Kinetic` tag; selling Common augments here refunds extra gold vs. other districts.
- **Skyline Casino** — Corp-affiliated, vice-flavored: Bouncer Squad / Augmented Gladiator enemies, hot-magenta neon-and-chrome aesthetic. Cheaper rerolls and an optional high-roller terminal to wager credits for rare/legendary augment drops.
- **Precinct Ruins** — abandoned law-enforcement zone squatted by Rogue Enforcer Bots and freelance Bounty Hunters; faded blue-grey aesthetic with broken evidence-locker holograms. Event node is a bounty board: optional harder mini-fight against a named elite for a guaranteed Rare+ augment.
- **Undercity Transit** — Street Runner / smuggler-adjacent enemies, rust-orange flickering-fluorescent tunnel aesthetic. Recruitment-leaning shop like Slum Market but cheaper/riskier: units offered here have randomized hidden traits revealed only on purchase.

#### Additional concepts (mechanics TBD — placeholder for later design pass)
Rounding the pool out toward 20. Faction/enemy/aesthetic are set; shop specialization and event design are deferred until the core loop is more robust.

- **Megachurch of the Machine** — AI-worshipping cult; Zealot Construct / Prophet Drone enemies; gold-and-white cathedral-like server-hall aesthetic with glowing halo lighting. Rogue AI–adjacent.
- **Freight Docks** — cargo port smuggling zone; Dockhand / Customs Enforcer enemies; shipping-container aesthetic, sodium-orange floodlights, fog. Street Runner–adjacent.
- **The Undernet** — deep hidden darknet space, distinct from Server Vault; Ghost Process / Corrupted Construct enemies; glitchy black-and-green matrix aesthetic with static distortion. Rogue AI.
- **Chop Shop Row** — black-market cybernetics surgery strip; Black Clinic Guard / Augment Pirate enemies; sickly-green surgical lighting, exposed wiring, medical-industrial aesthetic. Fixers/Street Runner overlap.
- **Skyway Overpass** — elevated highway slum built atop the city; Highway Raider / Drone Racer enemies; rain, headlight streaks, stacked vertical neon aesthetic. Street Runners.
- **The Vault Exchange** — corporate stock-exchange trading floor; Market Enforcer / Algo-Trader Bot enemies; white-and-gold ticker-tape hologram aesthetic, glass towers. Corp Enforcers.
- **Sunken District** — flooded lower city, post-disaster zone; Scavenger Diver / Flooded Automaton enemies; teal water reflections, rust, submerged neon signage. Neutral/Street Runner–adjacent.
- **The Panopticon** — corp surveillance tower; Watcher Drone / Compliance Officer enemies; stark-white aesthetic with red scan-lines and one-way glass. Corp Enforcers.
- **Graveyard Yards** — decommissioned mech scrapyard-cemetery; Reanimated Chassis / Junk Reaper enemies; foggy, rusted, tombstone-like wrecked-mech aesthetic. Rogue AI/neutral.
- **The Bazaar of Static** — black-market tech bazaar in a dead signal zone; Static Cultist / Signal Thief enemies; broken-hologram, visual-noise, purple-haze aesthetic. Fixers.
- **Uptown Gala** — high-society corp event and heist target; Private Security / Socialite Bodyguard enemies; opulent gold-and-white ballroom aesthetic with fireworks. Corp Enforcers.
- **The Warrens** — dense underground tunnel slum, distinct from Slum Market's open-air chaos; Tunnel Rat / Warren Boss enemies; cramped amber-lantern-lit tunnel aesthetic with makeshift stalls. Street Runners.

### Crew Scaling
| District | Crew Size | Total Augment Slots |
|----------|-----------|---------------------|
| 1        | 2 units   | 6                   |
| 2        | 4 units   | 12                  |
| 3        | 5 units   | 15                  |
| Final    | 6 units   | 18                  |

New unit slots open through the shop — the player chooses when to spend gold on a new recruit vs. upgrading existing units' gear.

### Gold Economy
- Fights reward gold based on performance (fast wins = more gold)
- Flat district encounter payouts guarantee steady, spendable income each round
- Active Spend Economy: No round interest mechanic — players are encouraged to actively spend and invest their credits each round rather than hoarding gold
- Shops sell units and augments; rerolling costs gold
- Late-game sell loop: selling Common augments to fund Rare/Legendary purchases is intended and encouraged

### Events
Optional district nodes offering narrative vignettes with a binary choice — e.g., pay gold for an augment, or fight a mini-encounter to take it by force. Events add texture and high-risk/high-reward moments without being required to complete a district.

### Upgrade Mechanic (Deferred Detail)
Duplicate augments combining to upgrade tier (two Common copies → one Rare) and duplicate units promoting to a veteran version with a bonus passive are intended mechanics. Exact combination thresholds and veteran bonuses to be designed once the core loop is playable.

---

## 3. Combat System

### Structure
Fights are fully automated once the player locks their crew — no input during combat. The strategic layer lives entirely in the prep phase: who you field, what augments they carry, and the order units act in.

Units act in **speed order**. Each unit has a basic attack and a signature ability that charges via a mana bar. Fights resolve in real time and last roughly 10–30 seconds — fast enough to feel snappy, long enough for synergies to visibly fire.

### Unit Roles & Augment Slots
Each unit has **3 fixed augment slots** (Primary, Secondary, Passive). A unit's role determines which slot types are available:
- **Tank** — 2 defensive slots, 1 passive
- **Hacker** — 2 utility slots, 1 passive
- **Sniper** — 2 offensive slots, 1 passive
- **Fixer** — 1 offensive, 1 utility, 1 passive
- *(Additional roles to be defined during implementation)*

### Faction Traits
Units belong to one of several city factions. Fielding enough units of the same faction activates passive bonuses at thresholds of **2 / 4 / 6** units. Higher thresholds give exponentially stronger bonuses — a mono-faction crew of 6 maximizes trait payoff but sacrifices compositional flexibility.

**Planned factions:**
- Street Runners
- Corp Enforcers
- Rogue AIs
- Fixers
- *(Expand during implementation)*

### Augment Tag Chains
Augments carry one or more tags: `Viral`, `Thermal`, `Neural`, `Kinetic`. Tags create cross-unit synergy chains that trigger during combat. Power scales with commitment to a tag across the crew:

| Tier | Color | Behavior |
|------|-------|----------|
| Common | Blue | Single stat boost + tag carrier |
| Rare | Purple | Tag + conditional trigger effect |
| Legendary | Red | Tag + powerful activated effect, often cross-unit |

**Example chain (Viral):**
- Common: +8% attack speed, carries `Viral` tag
- Rare: carries `Viral` tag; when any Viral effect fires on your crew, this unit gains +15% attack speed for 2s
- Legendary: carries `Viral` tag; all Viral triggers on your crew fire simultaneously

### Faction × Augment Intersections
Running a faction-complete crew alongside a matching augment tag can unlock a unique combined bonus unavailable to mixed comps. These cross-system combos are rare, powerful, and represent the highest-skill expression of the "stacking" fantasy. Exact combos to be designed during implementation.

---

## 4. Meta-Layer (Intentionally Deferred)

The meta-layer is the persistent system that survives between runs. Its exact shape is not locked — the core loop must be playable and fun first. It must:
- Give runs long-term context so each attempt feels part of something larger
- Unlock new content gradually (new operatives, augments, district variants, factions)
- Never punish the player — death is a setback, not a loss of progress

**Three candidate directions (to evaluate after core loop is built):**

1. **Reputation Network** — completing runs or reaching certain districts builds standing with city factions. Higher rep unlocks new starting operatives, faction-specific augments, or modified encounters in future runs.

2. **Persistent City Map** — districts cleared leave marks on the city (a contact, a stash, a bounty). Future runs start with the city in a state shaped by prior runs.

3. **Crew Legacy** — operatives who survive a completed run can be retired to a roster and redeployed in future runs as a starting unit with one kept augment. Your history is written into who you can field.

These directions are not mutually exclusive. Design begins after MVP core loop is validated.

---

## 5. Art Direction

### Visual
- **Palette:** Deep purples, electric blues, hot pinks, cyan accents
- **Aesthetic:** Neon Noir — rain-slicked surfaces, holographic overlays, heavy shadows
- **UI language:** Hacker terminal — monospace fonts, scanline textures, glowing data readouts
- **Unit portraits:** Stylized rather than realistic; neon-lit silhouettes with visible augment glow on the body
- **District environments:**
  - Corporate Arcology — cold chrome, white light, clean geometry
  - Slum Market — warm orange, cluttered neon signage, organic chaos
  - Server Vault — deep blue, pulsing data streams, geometric grids
  - Black Site — muted tones, red emergency lighting, oppressive scale

### Audio (Direction, Not Implementation Scope)
- **Score:** Synthwave / dark ambient
- **UI sounds:** Keystrokes, data pings, terminal feedback
- **Combat effects:** Electrical crackle for Neural/Kinetic augments, wet glitch sounds for Viral, heat distortion for Thermal

---

## Open Questions (For Later)

- Exact faction × augment combo bonuses
- Number of distinct factions at launch
- Meta-layer direction selection
- Duplicate upgrade thresholds
- Enemy AI composition design (how enemy crews are built to counter different player strategies)
- Win condition variants (standard boss kill only, or additional run modifiers?)
- 3-vs-4-normal-district run-length variance: the district pool and random draw are implemented (`DataRepository.draw_run_districts`), but a run currently always draws a fixed 3 normal + 1 final district because `Constants.DISTRICT_CREW_LIMITS`/`DISTRICT_SHOP_ODDS` only define a 4-step scaling curve. A 4-normal-district run needs a 5th step designed before that variance can be turned on.
- Mechanics (shop specialization, event design) for the 12 placeholder districts added to the pool (Megachurch of the Machine, Freight Docks, The Undernet, Chop Shop Row, Skyway Overpass, The Vault Exchange, Sunken District, The Panopticon, Graveyard Yards, The Bazaar of Static, Uptown Gala, The Warrens) and boss units for all newly-added districts (currently placeholder `boss_*`/`boss_tbd_*` ids with no matching `UnitResource`)
