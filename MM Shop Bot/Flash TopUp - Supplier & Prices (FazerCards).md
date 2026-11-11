# Flash TopUp — supplier & prices (FazerCards), 6 Nov 2026

## Supplier
- **FazerCards reseller API** — reseller.fazercards.com, panel at /panel, account `flashtopup`.
- API base `https://api.fzr.cards/api/v2`, header `X-API-Key`. Key lives only in `mmshop\.env` (`FAZER_API_KEY`).
- Replaced MGC (API kept failing, no MM coverage). Adapter: `mmshop\fazer.py`; bot delivery mode `fazer`.
- Plan: 5-day Gold trial (best discount) until 10 Nov 2026 20:19; after that pick the cheapest plan (Bronze) — check /panel/profile → Plan & renewal.
- Deposit: **USDT on BNB Chain (BEP20) only**, min $10, address shown at /panel/balance (0xdB3D…9bAe). Binance Pay also offered. Wrong coin/network = lost unless support recovers.
- 6 Nov: first deposit sent as BTC (BTCB over BEP20) by mistake → support ticket open; second deposit to be sent as USDT.

## Categories used
- `mobile_legends_global` — fields player_id + server_id. Works for all regions except Indonesia & Brazil; pack restrictions only for MY/SG/PH/ID/RU → Myanmar gets the full catalog.
- `pubg_mobile_auto` — field player_id, global, automatic delivery. (`pubg_mobile_fast` = same packs, slightly dearer.)

## Pricing rule
- `USD_RATE=4500` MMK/USD (change with `/setrate`), **25% markup**, rounded to 50 Ks. Re-check rate weekly against KBZPay dollar rate.
- Live products (bot DB, 6 Nov): 
  - MLBB: 10+1 1,350 · 20+2 2,750 · 78+8 6,250 · 156+16 12,350 · 234+23 17,900 · 625+81 48,550 · 1860+335 147,000 · 3099+589 245,250 · Weekly Pass 7,750 · Twilight Pass 41,000 · First Top-Up Bonus 50+50 4,000 / 150+150 11,900 / 250+250 19,100 / 500+500 39,200
  - PUBG: 60 UC 4,950 · 325 UC 24,700 · 660 UC 49,450 · 1800 UC 123,600 · 3850 UC 246,950 · 8100 UC 494,250 · Prime 4,950 · Prime Plus 49,500 · Elite Pass 29,800
- Hidden (worse value duplicates): 51+5, 102+10, 284, 504+66, 1007+156, 2015+383. Old stock-mode products 1–3 hidden.
- Supplier cost reference (USD): 78+8 $1.11 · 156+16 $2.20 · 234+23 $3.18 · 625+81 $8.64 · 1860+335 $26.14 · 60 UC $0.88 · 325 UC $4.39 · 660 UC $8.79 · 1800 UC $21.97.

## Bot admin commands (full mode)
`/fz` games · `/fz <category>` packs · `/fzbalance` · `/fzimport <category> <markup%>` · `/fztopup <pid> <category> <offer>` · `/setrate <mmk>` · `/products` · `/price <id> <mmk>` · `/hide|/show <id>` · `/pending` · `/stats`

## Go-live checklist
1. USDT deposit credited → `/fzbalance` shows it.
2. Test order: MLBB 10+1 (1,350 Ks) to own ID, approve, confirm diamonds arrive.
3. Post price list in Telegram channel; TikTok launch video.
4. Keep wallet ≥ $20; top up when `/fzbalance` < $15 (one 625+81 order is $8.6).
