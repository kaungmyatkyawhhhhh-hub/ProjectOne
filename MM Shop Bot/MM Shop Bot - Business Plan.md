# MM Shop Bot — selling Telegram order bots to Myanmar shops (Nov 2026)

## What it is
A Telegram order bot for any Myanmar online shop: catalogue → order form → KBZPay/WavePay details → customer sends slip → owner taps Approve/Reject → customer gets confirmation. Shop fulfils its own orders, so no supplier, no API, no MM-region problem (this is what killed Flash TopUp — MGC API failing, no Myanmar support).

Code: `shopbot.py` (single file, SQLite). One copy per shop with its own `.env` + `shop.db`.

## Why this instead of selling products
- $35, no card, no reputation → every physical product loses to the big shops. This sells TO those shops.
- Shops run hundreds of orders/day by hand in Messenger/Telegram; Facebook blocked (VPN now illegal) → they are moving to Telegram anyway.
- Telegram = main order/community channel in Myanmar 2026; TikTok for discovery, checkout off-platform (see research note).
- Capital needed: one $5/month VPS. That's the $35.

## Pricing
- Setup: 150,000–300,000 Ks (one-time, includes loading up to 30 products + staff training).
- Hosting/support: 30,000–50,000 Ks/month.
- Target: 10 shops in 90 days ≈ 2M+ Ks setup + 400k Ks/month recurring.

## Sales plan (no reputation needed)
1. Demo bot: make a bot for one real shop free (friend's shop / FlexiToysMM itself) in exchange for a public review + screenshots.
2. TikTok: 30-sec "order from this shop in 3 taps" video; post daily variants (catalogue, slip → approve, customer confirmation).
3. DM shop owners on Telegram/TikTok with the pitch below. Target: power-cut product shops (hottest demand, stock-outs → many orders), Thai-goods shops, cosmetics, snacks — anyone taking orders in chat.
4. Offer "first month free, pay setup only if you keep it".

## Pitch (Burmese) — paste into Telegram/TikTok DM
```
မင်္ဂလာပါ 🙏 ဆိုင်ရဲ့ အော်ဒါတွေကို chat ထဲမှာ တစ်ခုချင်း လက်နဲ့ လက်ခံနေရတာ ပင်ပန်းမလား?

ကျွန်တော်တို့က Telegram Order Bot လုပ်ပေးပါတယ် —
✅ ပစ္စည်းစာရင်း + ဓာတ်ပုံ + ဈေးနှုန်း bot ထဲမှာ
✅ customer က နာမည်/ဖုန်း/လိပ်စာ ဖြည့်ပြီး KBZPay slip ပို့
✅ ဆိုင်က Approve ခလုတ် တစ်ချက်နှိပ်ရုံ — customer ဆီ အတည်ပြုစာ အလိုအလျောက်ရောက်
✅ အော်ဒါအားလုံး တစ်နေရာတည်းမှာ စာရင်းရှိ — chat ထဲ ပျောက်မသွားတော့ဘူး

ပထမလ အခမဲ့ စမ်းသုံးနိုင်ပါတယ်။ demo ကြည့်ချင်ရင် "demo" လို့ reply ပေးပါ 😊
```

## Pitch (English, for shops run by Chinese/foreign owners)
```
Hi! Still taking orders one by one in chat? We build a Telegram order bot for your shop: product catalogue with photos, customer fills name/phone/address, uploads KBZPay slip, you tap Approve, customer gets an automatic confirmation, all orders listed in one place. First month free — reply "demo" to try it.
```

## Steps this week
1. Create demo bot via @BotFather, run `shopbot.py` on your PC, load 5 products (use FlexiToysMM items or any shop).
2. Record the TikTok demo (screen record phone: /shop → order → slip → approve → confirmation).
3. Post on TikTok + send the pitch to 20 shops/day.
4. First paying shop → buy VPS (Contabo/Hetzner/DigitalOcean $5), move bots there.

## Later features (charge extra)
- Delivery fee by city, order status "shipped" with tracking no.
- Stock counts, daily sales summary to owner.
- Broadcast promo to all past customers.
- Multi-admin, Burmese/English toggle.
