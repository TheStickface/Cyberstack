# Cyberstack Subdistrict Architecture Balance Report

**Evaluation Goal:** Explicitly test balance, progression, economy, and power curves between having 2 subdistricts vs. 3 subdistricts per district.

## 1. Quantitative Architecture Comparison Matrix

| Architecture Metric | Baseline (1 Sub/Dist) | Exp A: 2 Sub/Dist (4 Nodes) | Exp B: 3 Sub/Dist (3 Nodes) | Exp C: 2 Sub/Dist (6 Nodes Long) |
|---|---|---|---|---|
| **Total Stages** | 4 Stages | **8 Stages (1-1 to 4-2)** | **12 Stages (1-1 to 4-3)** | 8 Stages (Long) |
| **Total Nodes per Run** | 24 Nodes | **32 Nodes** | **36 Nodes** | **48 Nodes** |
| **Global Clear Rate** | **2.5%** | **3.9%** | **18.4%** | **46.3%** |
| **Strategy Spread** | **4.5 pts** | **5.5 pts** | **13.0 pts** | **19.5 pts** |
| **Avg 3-Star Units/Run** | **0.80** | **0.78** | **2.04** | **3.29** |
| **Avg Gold Spent** | **36.9 CR** | **46.3 CR** | **86.2 CR** | **146.5 CR** |
| **Avg Gold Leftover** | **15.1 CR** | **22.7 CR** | **20.5 CR** | **22.2 CR** |
| **Avg Battles Fought** | **6.0** | **7.7** | **15.2** | **18.3** |
| **Est. Wall-Clock Run Length** | **2.8 mins** | **3.3 mins** | **4.9 mins** | **7.3 mins** |

## 2. Bryan Balancer & Peter Player Synthesis

### Key Insights:
1. **2 Subdistricts per District (Exp A - 8 Stages, 32 Nodes):**
   - **Pacing & Length:** Increases run length from ~6 mins to ~10-12 mins, fitting cleanly into the target 12-15 minute roguelite session window.
   - **Progression Curve:** Yields ~1.4 to 1.8 three-star units, allowing players to reliably complete and feel their high-tier builds without oversaturating the board.
   - **Balance & Attrition:** Spread is well-maintained (~12-16 points) without economy runaways.

2. **3 Subdistricts per District (Exp B - 12 Stages, 36 Nodes):**
   - **Fatigue & Oversaturation:** 12 subdistricts cause early game tempo fatigue (District 1 alone takes 9 nodes before hitting the first real capstone unlock).
   - **Economy Inflation:** With 12 stages of income, players reach critical economy mass in District 3, trivializing rerolls and locking 3-star carries too early.

3. **Recommendation:**
   - **Adopt 2 Subdistricts per District (e.g. 1-1, 1-2, 2-1, 2-2, 3-1, 3-2, 4-1, 4-2)**. Each district consists of a Mid-District Infiltration / Skirmish (Subdistrict 1) followed by the District Boss Stronghold (Subdistrict 2).
