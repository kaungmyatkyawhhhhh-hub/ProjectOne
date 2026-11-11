# Myanmar Automated Business — Research (5 Nov 2026)

Goal: self-serve digital business selling to Myanmar customers via Telegram/Viber, Claude builds and runs; owner only approves payment slips (one tap) until auto-confirm is live.
FX used: ~4,400 MMK/USD market rate. Prices in MMK.

## 1. Payment automation — what an individual can get in 2026
Bottom line: fully automatic KBZPay/Wave confirmation is possible for an individual through ONE route (MyanMyanPay MMQR), needing a Myanmar NRC + Myanmar bank account. Everything else is company-only, too expensive, or screenshot-and-human.

| Option | Access | Fees | Automation | Verdict |
|---|---|---|---|---|
| MyanMyanPay MMQR (myanmyanpay.com, docs.myanmyanpay.com, SDK github.com/nawing/MMPay-Node-SDK) | Individuals: NRC + local bank account + bank-book photo; 1–2 day review | API plan 100 MMK/successful payment; hosted storefront 500 MMK/order; 120,000/yr fee waived to 31 Dec 2026; 2027 fees TBD | One-time amount-locked MMQR per order; HMAC webhooks; sandbox. Pays from KBZPay/Wave/AYA/CB/UAB/A+/MAB/Yoma | Only true self-serve rail. Caveats: 24h hold, disbursement in Mon/Thu batches, min payout 10,000, requests >14 days voided, no sub-merchant/reseller use, CBM licence pending (filed Jul 2026). Live proof: BShop Myanmar (t.me/Bshopautobot) auto-detects MMQR. |
| Dinger (dinger.asia) | Digital application but 100,000 MMK/month + 1-yr contract | KBZPay 1.9%+100; Wave 3.4%+100; AYA 0.7%+100; CB 1.5%+100; UAB 0.9%+100; cards 3.9%; "15%" for digital content via KBZ | Full API, webhooks, pay-by-link | Too expensive at launch; revisit >2M MMK/month |
| KBZPay merchant API direct | KBZ business onboarding, KYC, MCC | not public | notify URL, dynamic MMQR | Not realistic for an individual |
| KBZPay Mini App | BRD + business docs + UAT | n/a | in-app | Skip |
| Wave "Pay with Wave" / Merchant app | partner program; merchant app gives dynamic QR + push notifications, no individual API | n/a | app-level only | notification source only |
| Telegram Stars | any bot, no KYC | ~30% effective; payout in TON after 21-day hold, 1,000-star min | instant | Myanmar users lack cards; payout is crypto (CBM ban on paper, unenforced). Optional second rail for diaspora |
| Personal KBZPay/Wave + slip photo + admin approve | Level-2 KBZPay (NRC matches SIM) | 0 | Semi: bot collects slip, Claude vision extracts amount/txn ID/time, dedupes; owner taps Approve | How every Myanmar digital seller operates (DigitalVerse, Escanor-X, M Game Coin, Recap-shan bot, SalePilot). Risk: AI-forged slips (Wave public warning 2025) — owner cross-checks in-app history |
| Android notification listener → webhook (MacroDroid on spare phone) | anyone | 0 | fragile | nice-to-have to pre-fill approve card |

Limits: KBZPay Level 2 — 1,000,000/txn, 5,000,000/day; Level 1 — 200,000/500,000. Not a constraint at these tickets. Account-freeze risk is: keep balances low, sweep to bank, move to MMQR asap.
Money-out: all rails settle in kyat in Myanmar; moving to SGD legally is hard. Measure the goal in-country / reinvest in-country.
Regulatory: Ministry of Commerce online-sales registration for individuals (30,000 MMK, 2-yr, Myanmar resident ≥18; covers paid online education). Enforced since Jan 2024.

## 2. Shortlist
### A. EPS-TOPIK (Korean work-visa exam) prep bot in Burmese — PICK
- Telegram bot: free daily quiz, paid full mock tests (reading + listening w/ TTS audio), Burmese grammar/vocab decks, spaced repetition, AI tutor explaining mistakes in Burmese, UBT timed mode. Later JLPT N5/N4, JFT-Basic.
- Demand: 48,000 took the 2024 manufacturing EPS-TOPIK (5,540 passed); 37,957 applicants in 2025 2nd batch; overnight queues; years of prep. Japan: 3,305 JFT-Basic takers Dec 2025; JLPT seats sell out in days.
- Competitors: TopikGo (50K+ downloads, 2.1★), EPS TOPIK by ebzits (1K+), Excellent K (iOS, 0 ratings), jobploy.kr free, Korean Language Class TG 11.4K (English). Course comparables: Digital Products Myanmar courses 10,000; Japanese self-study channel (25.2K subs) sells Duolingo ~3,000/mo via Viber. No Telegram-native Burmese-first AI-explained EPS product found.
- Payment/delivery: slip-approve → unlock; v2 MMQR webhook. Zero-effort delivery.
- Build: medium. Own-written questions modelled on free official HRD Korea textbooks (don't redistribute PDFs); Korean TTS; Burmese via Claude (Burmese tokens 3–5× English — cap tutor calls).
- Margin ~90%+. Risk: seasonality (batches Feb–May, Jun–Oct); content QA by a Korean speaker once; copyright if official materials copied verbatim.

### B. Burmese CV / cover letter generator bot
- 3,000–5,000/PDF, 7,000 bundle. JOIM job channel 70.5K subs. Competitors: jobsinyangon free CV maker, Canva, resumly.ai (English, card). No Burmese Telegram bot found. Low–medium build, ~95% margin. Risk: one-off, free substitutes, Burmese-font PDF pipeline (Pyidaungsu/Noto Myanmar). Best as cross-sell inside A.

### C. Burmese AI assistant credit packs
- 2,000–10,000 packs. Evidence: DigitalVerse sells ChatGPT Plus share 19,900/mo, Gemini Pro slots 14,900; Monica AI #8 top-grossing on Play Myanmar; Moti AI precedent (2,500 packs, modest sales). Margin 60–80%. Risk: free DeepSeek/Gemini; thin willingness to pay unless niched → folded into A's tutor.

### D. Telegram Premium/Stars reseller via Fragment API
- Kyat Shop: 3-mo 64,137 / 6-mo 85,533 / 12-mo 155,072; Stars 50=4,298 … 1,000=85,958. HSA Game Store, AKS TopUp (12,482 orders claimed), DigitalVerse 6-mo 90,000. Fragment API 0–0.25% commission, funded by TON/USDT. Margin ~25–40% Stars, 5–10% Premium. Risk: crypto inventory, TON volatility, ToS grey, dozens of incumbents. Downgraded.

### E. Game top-up reseller via M Game Coin API
- Largest digital category (MLBB, PUBG, Free Fire). MGC API w/ webhooks, 330+ shops, 8-second delivery; Escanor-X 500+ resellers, bot kits 50–80K/mo. Margin 5–10% (MLBB 172 diamonds 13,450 wholesale vs ~14,500 retail). Needs 20,000/mo plan + float. Downgraded on margin.

Rejected: astrology (deceptive to sell AI readings as genuine), VPNs (Cyber Security Law cl.70 jail), subscription account-sharing (ToS violation, manual re-issuing).

## 3. Recommendation: EPS-TOPIK Burmese prep bot (working name "KoreaPass") + CV add-on
Biggest verifiable pool of motivated payers (tens of thousands per cycle, 88% fail → repeat), zero fulfilment, no legal grey zone, no inventory, Telegram-only (no VPN), ~90% margin, natural 3,000–15,000 price points, incumbents poorly rated. Japan (JFT-Basic/JLPT) and Thailand packs as second/third on same engine.

v1:
1. /start → Burmese onboarding, pick track (EPS Manufacturing / Service; later JLPT N5, JFT-Basic)
2. Free: 5 reading + 1 listening Q/day with Burmese explanation; streak + leaderboard
3. Paid: 10+ full 40+40 timed mocks; 1,500+ vocab w/ Korean TTS + Burmese gloss; grammar in Burmese; "Explain my mistake" tutor (20/day cap); progress report
4. Payment: price list, KBZPay/Wave numbers + deep-link, send slip; Claude vision extracts amount/txn/time, dedupes, flags mismatch; admin card Approve/Reject; approve unlocks instantly. v2: MyanMyanPay MMQR webhook
5. Referral: +7 days both sides
6. Add-on: CV/cover letter PDF 3,000
7. Admin: /stats, broadcast, refund flag

Pricing (MMK): 7-day 3,000; 30-day 7,000; 90-day exam season 15,000; CV 3,000; bundle 90-day+CV 17,000.

Distribution:
- Telegram: own channel daily vocab cards; sponsored posts in Burmese education channels (Japanese self-study 25.2K, Digital Products Myanmar 10.9K; education category ~115K on Telemetrio); EPS study groups
- Facebook (owner via VPN): EPS-TOPIK Myanmar groups, MOEAF/agency comments; link to t.me only
- TikTok (21M adults): "one Korean word a day", "EPS question of the day"; bio link → bot
- Viber Community for 25+/small-town segment; weekly free quiz
- Korean tuition centres / overseas-employment agencies: referral code

## 4. One-time owner setup
1. @BotFather bot; admin account/channel for approve cards; public channel
2. Myanmar SIM in NRC name; KBZPay Level 2; Wave Pay; sweep-to-bank routine
3. MyanMyanPay KYC (NRC, Myanmar bank, bank-book photo); API keys; confirm fees before 1 Jan 2027. No NRC → must be in a Myanmar-resident relative's name (legal/relationship risk)
4. MoC online-sales registration (30,000) once revenue is real
5. Infra: Singapore VPS (~US$5–10/mo), Anthropic API key, Korean TTS key (Google/Azure), Postgres
6. Content QA: one session with a Korean-speaking Burmese tutor (~50–100K MMK)
7. Marketing: TikTok, FB page, Viber Community; ~100K MMK sponsored-post budget
8. Money-out policy: kyat stays in Myanmar

Key sources: myanmyanpay.com / docs.myanmyanpay.com; dinger.asia/pricing/eng; kbzpay.com merchant T&Cs + limits; bshopmyanmar.com; store.kyatshop.com; mgamecoin.com; digitalversemm.tech; t.me/s/JapaneseLanguageSelfStudy; t.me/s/Digitalproductsmyanmar; t.me/s/jobopportunitiesinmyanmar; Eleven Myanmar (EPS-TOPIK numbers, JLPT seats, MMQR adoption, Wave fake-slip warning); JPF JFT-Basic Dec 2025; Google Play listings (TopikGo, ebzits); myanmarinternet.info 2025 (VPN law); DFDL/Tilleke on online-sales registration; Telegram Stars docs; Fragment API; Nation Thailand (kyat 4,400).
