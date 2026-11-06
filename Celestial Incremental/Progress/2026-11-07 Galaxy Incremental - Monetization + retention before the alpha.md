---
date: 2026-11-07
tags: [galaxy, progress, monetization, retention, live-ops]
status: built and tested in Studio (PC + 667x375 phone); NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - Monetization + retention before the alpha (7 Nov, Claude Code)

Prompt: [[2026-11-07 Galaxy Incremental - Monetization + retention check]].

Checklist: #407 #414 #441 #442 #443 updated; new rows #498-#503.

Screens: `Progress/screens/2026-11-07-monetization/`.

## What already existed (checked in the code, not by keyword only)
| # | Item | Before |
|---|---|---|
| 1 | VIP / +1 Core Slot / Auto Roll passes | **Missing**. Only x2 Stardust in GameConfig.Passes; the store had only that card (the others were in the design note §9 only) |
| 2 | Premium | Missing |
| 3 | Playtime gifts | **Partly**: 5/15/30/60 min of today's playtime, 1 Essence each, in DAILY. No 10/20/40, no mixed rewards, no HUD timer |
| 4 | Favourite prompt | Missing |
| 5 | Invite | Missing |
| 6 | Experience notifications | Missing |
| 7 | EventController | Missing |
| 8 | What's New + ServerRestartScheduled + update gift | Missing (only BindToClose saving) |
| 9 | Mythic + Celestial badges | **Already done**: GameConfig ids at 0, the award code covers every rarity ("Collection" .. rarity) |

## What I built
1. **Passes** (GameConfig.Passes, **id 0 = hidden + no effect** until you send the ids):
   - **VIP:** +0.25x stardust (adds like the other boosts), +1 Essence every Supernova, a gold VIP pill on the overhead name tag, `[VIP]` before their chat name.
   - **+1 Core Slot:** 4 equipped cores (server slotsOf; the Forge shows a 4-slot row).
   - **Auto Roll:** one roll every 3 s while you have Essence, through the SAME roll code as the button (odds, pity, NEW core). AUTO ROLL ON/OFF in the Forge's EQUIPPED header; it's ON when bought.
   - **Store:** a 2-column grid of pass cards (x2 STARDUST, VIP, +1 CORE SLOT, AUTO ROLL) in the store's card style, live prices (GetProductInfo), OWNED state; phone = fits the width + scrolls.
   - **Server:** GalaxyStoreService handles every pass the same way (UserOwnsGamePassAsync on join, PromptGamePassPurchaseFinished, save after a purchase).
   - Studio switches: `TestOwnPasses`, `TestShowPasses`.
2. **Premium:** Premium players +0.1x stardust (MembershipType, rechecked on PlayerMembershipChanged).
   - A PREMIUM chip in the boosts column: gold "+10%" for Premium; for others it's grey, and a tap opens Roblox's Premium prompt (once a session at most).
3. **Playtime gifts:** 5 / 10 / 20 / 40 / 60 min of today's playtime: 3 min of stardust, +1 Essence, +1 Essence, 2x stardust for 10 min, +2 Essence.
   - Essence is still 4 a day, as before (never less).
   - DAILY shows 5 tiles. A **GIFT chip** on the right of the HUD shows the next gift's real countdown (server time played, ticking each second) or GIFT READY!; a tap opens DAILY.
4. **Favourite:** AvatarEditorService:PromptSetFavorite once, right after your FIRST Supernova (when the cutscene is over). Any answer = never again.
5. **Invite:** INVITE on the FRIENDS chip: SocialService:PromptGameInvite, only if CanSendGameInviteAsync. LaunchData = who invited.
6. **Notifications:**
   - **Opt-in:** Roblox's opt-in prompt once, 90 s into your 3rd+ session (after the tutorial, nothing open).
   - **Offline full:** "Offline full" is queued when you leave (MemoryStore, due when your offline cap fills, cancelled if you come back); any server sends it via Open Cloud, max 1 a day.
   - **Weekly:** the weekly message is sent once per `weeklyVersion` to players seen in the last 28 days.
7. **EventController** (GameConfig.Events, GalaxyLiveService):
   - Every server reads the UTC clock each second and runs the event that's on.
   - The alpha 2x STARDUST HOUR is set for **Sat 21 Nov 15:00 UTC, every 7 days**. An event is +1x stardust, adding like the rest.
   - The banner at the top shows the real time left.
8. **What's New** (GameConfig.WhatsNew, version 1):
   - **The window:** opens once per version, after the tutorial, when nothing else is open.
   - **Gift:** everyone who played before gets the version's gift once (+2 Essence now). Brand-new players skip both.
   - **Restart:** `game.ServerRestartScheduled` shows "UPDATE INCOMING! 0:59 · SAVED" and saves every player right away.
9. Badges: nothing to do (send the 2 ids).

## Tests (Studio)
- **Passes:** with TestOwnPasses, CoreSlots = 4 and the Forge showed 4 slots. Auto Roll did 4 rolls in 10 s (Essence 14 → 10), the switch turned it OFF, and rolling stopped. BOOSTS included VIP's +0.25. The VIP pill showed on the name tag.
- **Premium:** this Studio account has Premium: Premium = true, BOOSTS x2.2 = x2 pass + group + Premium.
- **Events:** **EventController test**:
  - 19:52:18 UTC: I set a test event to start 2 minutes later.
  - At 19:54:18 UTC exactly, EventId = Test2x, 180 s long. The banner showed "2x STARDUST HOUR · 2:53 LEFT" and BOOSTS went x2.2 → x3.2.
  - The real one is scheduled for 1795273200 (= Sat 21 Nov 15:00 UTC).
- **Gifts:** claimed 10 min (Essence 27 → 28) and 40 min (BOOSTS +1, x2 STARDUST card 10:00). GiftsGot updated.
- **What's New:** opened after the return screen, GOT IT saved SeenVersion = 1. The update gift came on the next join (Essence 2 → 4).
- **Restart:** TestRestart showed the UPDATE INCOMING banner with a countdown.
- **Phone:** STORE, DAILY, What's New, HUD screenshots taken; fixes from them: the What's New line wrap, the x2 badge, and the boosts column now smaller and lower on phones.
- No console errors at the end (one `refresh` called before it was defined in GalaxyPotions: fixed).

## NOT tested (say so plainly)
- **2-client test:** NOT possible with my Studio tools (they start one player only). The playtime gifts were tested with one player.
- **Invite:** NOT tested in a real flow; Roblox's invite prompt doesn't appear in Studio play.
- **Favourite prompt:** not seen. This save is past its first Supernova, and it only fires on 0 → 1.
- **Notifications:** the opt-in prompt and the sending are untested (Studio can't send; needs your message ids + API key).
- **[VIP] chat tag:** the code is in. Studio didn't draw the chat window in screenshots, so it's not seen.

## You need to
1. Create the 3 passes (VIP 399, +1 Core Slot 349, Auto Roll 199) and send the ids. Icons 512x512 (they show as circles).
2. Notifications: make 2 messages in Creator Hub (Engagement > Notifications):
   - "Your offline stardust is full!"
   - the weekly update

   Then make an Open Cloud API key with user-notification write and save it in the game's Secrets as `NotifyApiKey`. Send me the 2 message ids.
3. The Mythic + Celestial badge ids.
4. Share Links: there's no Roblox API to attach a Share Link to PromptGameInvite. The invite carries LaunchData (who invited) instead.

## Flags
- **Auto Roll spends ALL your Essence** (it's what the pass says). This test save went 28 → 2. If you want a "keep N Essence" floor, say so.
- **Playtime = today's minutes, not "this session":** it counts real minutes played today (resets daily, as before), so leaving and rejoining never loses progress or lets you farm gifts.
- **The test save:** this Studio save got the update gift twice (by the test switch) and spent its Essence on Auto Roll.
- **DAILY on the phone:** the gift labels are small there (the whole window is small on phones, as before).
