---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.6: RING 2 complete (6 Nov, Claude Code)

Step 2.6 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. Checklist rows: **#53 #54 #56 #135 #136**.
(Built together with 2.2, because the tree needed one new layout for all 4 branches.)

## What's new
- **COMETS branch (#53), PROPOSED prices:**
  - **COMET CHAIN** 150 shards, Supernova 8: catch 3 in a row, the 3rd pays x2. A comet that flies past breaks the chain.
  - **GOLDEN COMETS** 300 (was 400), Supernova 10: 1 comet in 20 is gold and pays x10 (every run; run 1 keeps its own 1 in 10 x5).
  - **COMET TAIL** 500 (was 900), Supernova 12: a chain also pays 60 s of income. A "CHAIN x2 +..." pop on the counter.
- **FORGE branch (#54), CHANGED:**
  - The design's "Forge unlock" node is gone: the Forge opens at IGNITION 1 since 5 Nov.
  - BULK x3 was already free, so **BULK ROLL** makes it **x10**.
  - **STAR ESSENCE** 300 (was 500), Supernova 11: +1 Essence a Supernova.
  - **FORGE LUCK** 600 (was 1,500), Supernova 13: +10% luck.
  - **BULK ROLL** 900 (was 2,500), Supernova 15.
- **CAPSTONE (#56):** a wide tile under the tree; INFO shows the 3 choices.
  - **IDLE STAR:** x3 income, comets off.
  - **COMET CHASER:** comets x5.
  - **FORGE MASTER:** +2 Essence a Supernova, +25% luck.
  - First pick: 500 shards (was 1,000; re-priced after bot run 1) at Supernova 12. Switching is **free once after each Supernova**, otherwise "switch after your next Supernova".
- **BUY ALL (#136):** buys every ring-2 level you can pay for, cheapest first (the server picks).
- **The tree shows the next 2-3 nodes (#135):** 4 columns (STELLAR / COMETS / FORGE / AUTOMATION). Each shows the node you're on, the one before it and the next one; further nodes are a dark "?". A locked node shows what opens it.

## Tests (Studio test save)
- Capstone (tested at the old 1,000 price): COMET CHASER cost 1,000 shards; switching straight after was refused ("swap"); after a Supernova, the switch to IDLE STAR was free, and a 2nd switch was refused.
- That Supernova paid 1 + 1 Essence (base + STAR ESSENCE).
- BUY ALL bought 6 nodes (Golden Comets, Comet Tail, Star Essence, Forge Luck, Bulk Roll, Long Night) and left the ones locked at Supernova 16.
- Found + fixed: the capstone page cut its 3rd line and a long caption (screen `2.6-pc-capstone-BEFORE-text-fix`).
- Bot run 2 (90 min): the capstone (IDLE STAR) at minute 37.5 (Supernova 15); BUY ALL bought CometChain 19.5, GoldenComets 22.8, StarEssence 29.8, BinaryStar 57.2, CometTail 63.5, LongNight + ForgeLuck 81.3, BulkRoll 88.1. Prices re-priced after run 1 (see 2.2). Report: [[2026-11-06 Galaxy Incremental phase 2 - REPORT]].
