# Automated Business — Niche Research (5 Nov 2026)

Goal: a fully self-serve micro-SaaS that Claude builds and operates; owner does one-time setup only. $100 → $1000/month target.

Method: ~45 web searches/fetches. Prioritised verified revenue (TrustMRR Stripe-verified listings, founder interviews with numbers) and real buyer threads over listicles.

## Dropped early (fail constraints)
- Etsy tools — Etsy API commercial approval takes months / gets banned (https://github.com/etsy/open-api/discussions/1607)
- Google-review alert tools — Google Business Profile API needs manual approval; Places API returns only 5 reviews
- Screenshot/OG-image APIs — price war (PageBolt $49 vs ScreenshotOne $99 vs Urlbox $149 per 10k req); new entrants at $0
- YouTube/podcast transcript tools — YouTube-to-Transcript at $215 MRR on 20k WAU, for sale at $15k; scraping fragile
- Generic uptime / status pages — free tiers everywhere (UptimeRobot, Better Stack); Hosted Status Page $118 MRR / 6 subs

## Shortlist

### A — PDF bank statement → CSV/Excel/QBO converter  ⭐ PICK
- Problem: banks only give PDFs beyond ~90 days; QuickBooks/Xero feeds don't backfill. Bookkeepers retype or pay Fiverr.
- Who pays: bookkeepers/CPAs, small-business owners, loan processors, forensic accountants.
- Competitors: Bank Statement Converter (solo, $30/mo 400pp, $99/mo 4000pp; ~$16k MRR, ~$500/mo costs — https://founderreports.com/interview/bank-statement-converter/ ; IH "$10k MRR on autopilot"); DocuClipper ($29/$159/$399; 125 G2 reviews 4.6★); Bankconv (~$600 MRR, 21 subs — https://trustmrr.com/startup/bankconv); Bankstatemently (Singapore founder, $375 MRR, 14 subs — https://trustmrr.com/startup/bankstatemently); StatementSheet ($1.1k/mo self-reported).
- Demand: Similarweb Sept 2026 — bankstatementwizard.com 385k visits/mo, statementconvert.com 238k, docuclipper.com 80k, bankstatementconverter.com 61k. AccountingWeb UK thread https://www.accountingweb.co.uk/node/216094 ; r/automation thread complaining generic PDF converters "get messy"; dozens of Fiverr gigs.
- Fit: upload → pay → download; customer's own data; no scraping, no credentials, no API approvals.
- Build: low–medium. Upload → LLM vision extraction → balance check → CSV/XLSX/QBO/OFX. 3–5 days MVP. (Founder write-up: https://dev.to/pnkjjsr/how-i-built-an-ai-tool-that-converts-any-bank-statement-pdf-to-excel-and-what-i-learned-6ho)
- Risk: head keyword saturated (dozen 2025–26 clones at $5–$600 MRR). Must win on a wedge. Parsing-failure tickets → Claude auto-triages, auto-refunds credits, deletes files after 24h.

### B — SSL cert + domain expiry monitoring (agencies/MSPs)
- TrackSSL: $19/$39/$79; verified $5,330 MRR, 223 subs, "no marketing effort" since 2022 (https://trustmrr.com/startup/trackssl). domainnotifications.com $19.99/$39.99. Certpost $29/mo only $58 MRR; DNS Monit $9/mo $137 all-time.
- Demand: r/sysadmin MSP thread (Hudu check "only works for half our domains"); r/devops outages thread — but sysadmins recommend free inventory tools.
- Build: low, 2–3 days. Risk: free tiers everywhere; certs moving to auto-renew. TrackSSL's $5k is a 2017 SEO moat.

### C — Cron/heartbeat monitoring
- Healthchecks.io free 20 checks, $20/mo; verified $14k MRR, 652 customers, one person. Cronitor $49–199. Cronping $19/mo or $299 lifetime. Dead Man's Snitch from $6.
- Build: low. Risk: Healthchecks is open-source + generous free tier; devs rarely pay a newcomer. Expect <$500 MRR without a hook.

### D — Website/competitor page change monitoring
- Visualping $14–$350; PageCrawl $8/mo 100 pages; PageChange $19 (billing complaints); changedetection.io OSS.
- Fit: partial — needs fetching arbitrary pages (bot protection, JS). Risk: fragility, support load, cheap incumbent.

### E — DMARC report monitoring (SMB/MSP)
- PowerDMARC $8, VerifyDMARC $1, Postmark $14/domain, DMARCwise €15, dmarcian $24, EasyDMARC $44.99.
- Fit: self-serve, inbound email ingestion + XML parsing, 4–6 days. Risk: extremely crowded with free options; buyers default to free.

## Recommendation: Niche A with a bookkeeper + regional-bank wedge
Only niche with multiple verified solo operators above $1k MRR, six-figure monthly category traffic, and buyers who already pay humans. Satisfies every constraint. Wedge:
1. Bank-specific long-tail SEO pages for banks incumbents cover badly — SG/MY/ASEAN (DBS, OCBC, UOB, Maybank, CIMB, Public Bank, BDO, BPI, Kasikorn), Gulf, India, Africa. This is how Angus Cheng started (HSBC HK pages).
2. Bookkeeper workflow: multi-client folders, batch upload, QBO/OFX/CSV-for-Xero, automatic balance reconciliation flag — which the $9–$29 clones lack.
$1,000/mo ≈ 45 customers at $19–$29 blended ARPU.

Name direction: trust/accuracy word + ledger/statement — Ledgerly Convert, StatementTally, BankToSheet (check availability). Keep "statement" in domain for SEO.

### v1 (MVP)
1. Drag-and-drop PDF (text or scanned); 5 free pages without signup, then magic-link signup.
2. LLM vision extraction (Gemini Flash / Claude Haiku) → date, description, debit, credit, balance; multi-line descriptions, DD/MM vs MM/DD, European numbers, multi-currency.
3. Automatic reconciliation check (opening + credits − debits = closing); mismatch flags; "verified ✓" badge — trust differentiator.
4. Export: CSV, XLSX, QBO, OFX, Google Sheets copy.
5. Batch upload (≤20 PDFs) + per-client folders.
6. Privacy: auto-delete after 24h; "we never store bank logins" copy.
7. Credits + subscriptions via Stripe (or Paddle MoR); auto-refund credits on failed conversion.
8. Programmatic SEO: /convert/[bank]-statement-to-excel for 150+ banks, each with sample + FAQ.
9. Claude-operated ops: nightly job reviews failed conversions, re-runs with stronger model, emails user, logs layouts for prompt tuning.

### Pricing
- Free: 5 pages/month
- PAYG: $9 for 60 pages (never expires)
- Starter $19/mo: 300 pages, all exports
- Pro $49/mo: 1,500 pages, batch, client folders, priority model
- (Later) Firm $99/mo: 5,000 pages, API

### Distribution
1. Google long-tail SEO: "[bank] statement to excel", "[bank] pdf to csv", "convert bank statement to QBO", "import old bank transactions quickbooks", "bank statement converter for bookkeepers". ~150 bank pages SG/MY/PH/TH/ID/IN/AE/ZA/AU + US/UK majors. Google Search Console day 1. Google Workspace Marketplace Sheets add-on.
2. Bookkeeper communities: r/Bookkeeping, r/QuickBooks, r/Accounting, r/smallbusiness, r/xero; QuickBooks Community; AccountingWeb UK; Xero Community; FB groups "Bookkeeping Business Owners", "QuickBooks Online ProAdvisors". Answer "how do I import PDF statements" threads.
3. Directories: Capterra/GetApp/Software Advice, G2, AlternativeTo ("DocuClipper alternative"), SaaSHub, Product Hunt; own comparison pages.

Fallback if SEO stalls after 90 days: pivot same engine to invoice/receipt-to-CSV for the same bookkeepers (DocuClipper's path).

## One-time owner setup
1. Payments: Stripe Singapore (individual: NRIC/passport + Singpass; sole-prop needs ACRA ~S$115/yr — https://support.stripe.com/questions/verification-requirements-for-stripe-accounts-in-singapore). MoR alternatives: Paddle (5%+$0.50), Dodo (4%+$0.40). Lemon Squeezy mid-migration into Stripe Managed Payments — prefer Paddle/Dodo or Stripe + Stripe Tax.
2. Domain + DNS: Cloudflare Registrar/Namecheap, Cloudflare DNS.
3. Hosting: Vercel (Next.js) + Railway/Fly (worker); Neon/Supabase Postgres; Cloudflare R2 with 24h lifecycle deletion.
4. LLM API keys: Google AI Studio and/or Anthropic, with spend caps.
5. Transactional email: Resend/Postmark, verified domain (SPF/DKIM/DMARC).
6. Auth: magic-link via Resend or Supabase Auth.
7. Analytics/SEO: Google Search Console, Bing Webmaster, Plausible/Umami.
8. Directory accounts: Capterra/GetApp, G2, AlternativeTo, Product Hunt, SaaSHub.
9. Legal: privacy policy + terms; support@ alias forwarded to a mailbox Claude can read.
10. Reddit/forum accounts with karma age; posts human-approved.
11. Spend caps: Stripe Radar, LLM budget alerts, Vercel/Railway limits.
