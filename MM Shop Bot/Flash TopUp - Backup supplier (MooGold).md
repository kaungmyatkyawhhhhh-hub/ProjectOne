---
date: 2026-11-06
tags: [flashtopup, supplier]
---
# Flash TopUp - Backup supplier research (6 Nov 2026)

## Why
- FazerCards: two 10.04 USDT deposits (BEP20, on time, Success on BscScan) not auto-credited because invoice needs the EXACT amount (10.00). Support hasn't answered tickets for 2 days.
- FazerCards Trustpilot: 6 reviews, 3.0/5; several say support never replies, orders stuck for days. Company says replies can take "several hours".
- Lesson: on Binance withdraw, set "Receive amount" = exact invoice amount.

## Candidate: MooGold (moogold.com)
- Trustpilot 4.4/5 from ~3,660 reviews (85% 5-star, 9% 1-star). Praise: fast, polite live chat. Complaints: some "instant" orders stuck on restock, refunds 7-14 days, sometimes only to MooGold wallet.
- Cheapest or near-cheapest for MLBB Myanmar on MangoRecharge compare (retail): 86 dia $1.15, 172 $2.27, 257 $3.29, 706 $8.94, 2195 $27.07. FazerCards cost was 78+8 $1.11, 156+16 $2.20, 625+81 $8.64, 1860+335 $26.14 -> MooGold retail is ~3-4% above Fazer cost; reseller pricing may be lower.
- API exists (doc.moogold.com). Access: create account, then contact MooGold (live chat) for partner_id + secret. Auth = user ID + partner ID + secret. Python client: github.com/dzmuh97/pyMooGoldApi.
- To ask MooGold: reseller API access; MLBB (Myanmar/global) + PUBG UC product IDs; wallet top-up methods (USDT BEP20? Binance Pay?); reseller discount tiers.

## Plan
- Bot gets a second delivery mode `moogold` next to `fazer`; pick per product. Keep FazerCards only for what MooGold lacks, with a small balance.
- Credentials go only into Vercel env vars (user pastes them), never typed by Claude.

Sources: trustpilot.com/review/moogold.com · trustpilot.com/review/reseller.fazercards.com · mangorecharge.com/compare/mlbb/mm
