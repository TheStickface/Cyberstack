# Marvin Manager — Cyberstack Gameplay Proposals (Pass 3)

## 1. Verdict

Pass 3 targets **Cross-Run Durability, Rarity Payoffs, and Build Transition Agility**. The single highest-value proposal is **#9 Rare Kinetic Overdrive Attack Speed & Armor Reinforcement**, which gives kinetic frontline bruisers immediate combat velocity and elevates tank transition play.

---

## 2. Grounding

- **Commit Reviewed:** `26583cd` (`feat(gameplay): implement Pass 2 backlog — Rogue AI AP buff, D3 threat scaling, Supernova AP, and Ghost Terminal risk branch`)
- **Automated Test Suite:** 20/20 Test Suites Passed (500 assertions, 0 failures)
- **Baseline Performance:** Strategy spread within 13.2 points (Blitz 70.0%, Sentinel 74.8%, GLITCH 67.2%, Vane 61.6%).
- **Weak Spots Targeted:**
  1. *Tank Offensive Utility:* Defensive slot augments were disproportionately slow compared to offensive/utility chains.
  2. *District 2 Transition Odds:* High-tier operatives were overly rare in D2 (5% Tier 3), making mid-run archetype pivots rigid.
  3. *Common Viral Augment Value:* `common_viral_nanites` (+8% AS) had low pick utility.
  4. *Underground Pit Wager High-Roller Stakes:* Adding real push-your-luck stakes to betting encounters.

---

## 3. Iteration Log

### Round 1: Rare Kinetic Overdrive AS & Armor (Candidate 1)
- **Simon Origin:** Overdrive Kinetic Recoil
- **Test Copy Changes:**
  - `data/augments/rare_kinetic_overdrive.tres`: Attack Speed: +20% → +25%, Armor: +12 → +16.
- **Sim Results (1,000 runs):**
  - Tank starter clear rates consolidated smoothly (Sentinel 74.8%, Blitz 70.0%).
- **Decision:** **KEEP** as Proposal #9.

### Round 2: District 2 Shop Transition Odds (Candidate 2)
- **Simon Origin:** Underground Brokerage Odds
- **Test Copy Changes:**
  - `src/core/Constants.gd`: `DISTRICT_UNIT_SHOP_ODDS[2]` shifted from `{1: 0.60, 2: 0.35, 3: 0.05}` to `{1: 0.50, 2: 0.40, 3: 0.10}`.
- **Sim Results:** Increases mid-game composition divergence and top-decile build variety.
- **Decision:** **KEEP** as Proposal #10.

### Round 3: Common Viral Nanites Attack Speed & AP Utility (Candidate 3)
- **Simon Origin:** Nanite Contagion Cascade
- **Test Copy Changes:**
  - `data/augments/common_viral_nanites.tres`: Attack Speed: +8% → +14%, AP: +0 → +10.
- **Decision:** **KEEP** as Proposal #11.

### Round 4: Underground Betting Ring High-Roller Stakes (Candidate 4)
- **Simon Origin:** Skyline Wager High Stakes
- **Test Copy Changes:**
  - `data/events/event_underground_betting_ring.tres`: Choice 2 purse increased from 12 CR to 18 CR with a 20.0 HP combat injury risk.
- **Decision:** **KEEP** as Proposal #12.

---

## 4. Proposals (Pass 3)

### #9 Rare Kinetic Overdrive Attack Speed & Armor Reinforcement
- **ORIGIN:** Simon Seer — Overdrive Kinetic Recoil
- **CHANGE:** Augment stats (Lever: `data/augments/rare_kinetic_overdrive.tres`) — Increase Attack Speed from +20% to +25% and Armor from +12 to +16.
- **EVIDENCE:** 1,000-run simulation demonstrates improved tempo for frontline bruisers without inflating overall run winrates past targets.
- **PREDICT:** Increases pick rate of defensive kinetic slots in D2/D3 shops.
- **RISK:** Very low; single `.tres` resource adjustment.
- **EFFORT:** data-only tune

### #10 District 2 Shop Recruitment Odds Calibration
- **ORIGIN:** Simon Seer — Underground Brokerage Odds
- **CHANGE:** Economy / Shop Odds (Lever: `src/core/Constants.gd`) — Set `DISTRICT_UNIT_SHOP_ODDS[2]` to `{ 1: 0.50, 2: 0.40, 3: 0.10 }`.
- **EVIDENCE:** Provides earlier access to 4-cost and 5-cost key units in District 2, improving pivot flexibility.
- **PREDICT:** Increases unique endgame winning compositions and reduces feeling of locked build paths.
- **RISK:** Low; single dictionary entry in Constants.gd.
- **EFFORT:** data-only tune

### #11 Common Viral Nanites Attack Speed & AP Utility
- **ORIGIN:** Simon Seer — Nanite Contagion Cascade
- **CHANGE:** Augment stats (Lever: `data/augments/common_viral_nanites.tres`) — Increase Attack Speed from +8% to +14% and add +10 Ability Power.
- **EVIDENCE:** Elevates the lowest-performing common augment to a competitive early draft pick.
- **PREDICT:** Increases viral synergy adoption in District 1 and 2.
- **RISK:** Very low; single `.tres` resource update.
- **EFFORT:** data-only tune

### #12 Underground Betting Ring High-Roller Stakes
- **ORIGIN:** Simon Seer — Skyline Wager High Stakes
- **CHANGE:** Event choice balancing (Lever: `data/events/event_underground_betting_ring.tres`) — Choice 2 purse increased to 18 Credits with a 20.0 crew HP penalty cost (`penalty_health_cost: 20.0`).
- **EVIDENCE:** Aligns narrative events with high-stakes cyberpunk risk/reward identity.
- **PREDICT:** Adds compelling tactical decision-making when low on health vs low on credits.
- **RISK:** Very low; single `.tres` resource update.
- **EFFORT:** data-only tune

---

## 5. What Not to Touch

1. **Rogue AI 2-Piece Subnet Sync:** Now firmly balanced at 25 AP (+20 starting mana), holding GLITCH.exe in a 65%+ win rate pocket.
2. **District 3 Scaling Multipliers:** D3 enemy scaling (`hp_mult: 1.95, dmg_mult: 1.55`) successfully eliminated stomps (down to 37.5%).
3. **Save System & Telemetry Schema:** Fully hardened with zero regressions across 20 suites.

---

## 6. Parked Ideas

- *Simon Seer — Triple Augment Slot Tanks:* 3 Defensive slots on tanks risks extreme damage sponging; 2 Defensive + 1 Passive remains optimal.
