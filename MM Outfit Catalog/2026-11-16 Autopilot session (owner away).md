---
tags: [mm-outfit-catalog, changelog, autopilot]
created: 2026-11-16
---
# Autopilot session, 16 Nov (owner away 2 h)
**Owner's words:**
- "while i go for 2 hours, keep working on the game, dont ask me any questions or permissions ... try to make it the best ever catalog game"
- "u can publish the place" (saved to Roblox throughout; going live is still the owner's click)

**Backups:** ScriptBackups `pre_Autopilot_16Nov`; map `MapBackups/pre_ThemeUploads`.
**Saves:** versions 165 to 177+ (Team Create, "Saved to Roblox"). Not published live.

## What changed
### Uploads (community looks)
- **More › Uploads page:**
  - "+ Publish a new look".
  - Your quota for today and today's challenge theme.
  - Your uploads, newest first, each with **Try** and **Remove** (double tap).
  - Staff can remove any look.
- **Daily challenge theme:**
  - One theme a day (`Config.ChallengeStyle`), preselected with ★ in the publish card.
  - A "★ TODAY'S CHALLENGE" pill on the Styles page.
- **Creator notice:** when someone tries on your upload while you're in the server, you get a pink chat line and a sound.
- **NEW tags:** uploads count as NEW for 2 days, so fresh community looks reach Featured.
- **Body parts travel with uploads:** Headless, Korblox, or a bundle body is saved as `body`. The look's mannequin and try-on use it. Tested: Korblox leg on the new model.
- **Top Creators board** on the Sky Deck: the 5 players whose uploads are worn the most (sum of worn counts). Refreshes every 2 min and when uploads change.

### Shopping & trying
- **Quick Try** on theme cards; worn counts and prices load without blocking Try/Buy (server lock bypass for read-only lookups).
- **See fit on other players** (new, big catalog-game staple):
  - Walk up to anyone and press **See fit** (F / tap / Y). This opens "<name>'s fit" with their classic shirt, pants and rigid accessories.
  - Each piece has **Try**, and taps open the item page (save, cart, buy).
  - **Try whole fit** copies their look, body parts included, with Undo / My avatar.
  - **Buy all** buys what's on sale.
  - Layered and off-sale items are skipped (the page says how many).
- **"wearing NEON STAR" tag** over other players who have a catalog outfit on (local, 45 studs). It makes fits around you visible.
- **Avatar page body editor:**
  - 8 skin tones.
  - Height: Short / Normal / Tall.
  - Width: Slim / Normal.
  - Body: Classic / Athletic / Slender.
  - Uses Roblox's own scale limits and goes through Undo / My avatar like a try-on.
  - Compact header on phones.
- **Search sort chips:** Popular (best-selling this week, paid items when no keyword), Newest, Cheapest, Priciest. Free items say "Free".
- **Search reliability:** the first search after joining sometimes never answers. It now re-asks every 6 s, up to 3 times.

### Growth
- **Invite** button in the More tray: Roblox's own friend-invite sheet (SocialService). It has a drawn two-people icon.
- **Loading tips** rotate: one-tap try-on, uploads reach the Sky Deck, theme sorting, See fit.

### Performance & reliability
- **Accessory type cache** (DataStore `MMAssetTypes_v1`): all 30 mannequins are complete within ~5 s (were 50–85 s, with missing hats under rate limits).
  - Incomplete rigs rebuild 20–30 s later.
- **Animation culling** for mannequins: about 18 animate instead of 52; the other floor's rigs pause.
- **Team Create editing fix:** script edits now go through the editor document (`UpdateSourceAsync`). See the memory note: setting `.Source` didn't reach open editor tabs, so Play ran old code.

## Tested in Play
- Every Collection page opened with no script errors.
- Board, See fit (server + page), Try whole fit guards, body editor (R15: skin, height, body type, undo count), upload with Korblox, search sorts.
- Phone checks (Galaxy A06 705×338): See fit page, Avatar page.

## Not tested / for the owner
- **See fit and the "wearing" tag need a second real player.** Studio Play has one, so the prompt and tag were checked in parts: the server answers for any user id, and the tag was rendered on a stand-in.
- The first open of See fit right after joining can take ~15 s while the mannequins load (ownership checks queue). It's instant after that.
- Publishing live is the owner's click.
- Still open from before: Lighting.Technology to Future, upload the sound files.
