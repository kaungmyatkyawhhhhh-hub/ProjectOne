# Stomp Evolution - Impatient kid rerun after "clicks give Mass, props give coins" (13 Nov, 11:45)

- **Code:** Calc/kid_1311b.py, built on livekid3.py (livekid2 plus a click option).
- **Results file:** kid_1311b_results.txt.
- **Model:** live build v126: guide arrow, 1 s evolve, landmarks, smash index, golden 1/80, an event every 90 s.

| version | 5 min stay | @7 s | @16 s | 1st buy | 1st evolve | forms in 5 min |
|---|---|---|---|---|---|---|
| A before (props give Mass, bare clicks 30%) | 96% | 81% | 100% | 8.4 s | 15.8 s | 6 |
| B v126 (every click 80% Mass, props coins only) | 92% | 64% | 99% | 12.2 s | 13.0 s | 5 |
| C clicks 100% | 97% | 78% | 100% | 15.9 s | 9.9 s | 5 |
| **D clicks 120% (now live, v127)** | **99%** | **89%** | 100% | 17.4 s | 8.4 s | 6 |

**Why B dropped:** props stopped feeding Mass, so the later forms came slower (5 forms instead of 6 in 5 minutes). Coins also come only from props now, so the first upgrade comes later.

**Fix:** `C.BareMass` 0.8 → 1.2. The very impatient kids (7 s patience) go from 64% to 89%, better than before the change. The first evolve is at ~8 s.

**Watch:** the first upgrade now comes at ~17 s (it was 8 s). If the real onboarding funnel shows kids missing the upgrade step, raise the welcome coins (10) a little.

This is a model; the real check is the onboarding funnel after publishing.
