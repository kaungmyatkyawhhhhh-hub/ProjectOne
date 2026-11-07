---
date: 2026-11-07
tags: [galaxy, progress, ui, mobile, live]
status: in Studio, tested (emulated devices); NOT published (the owner publishes)
---
# Galaxy Incremental - phone HUD, the real tycoon pad, rank tag, guide trail (7 Nov, game live, Claude Code)

Prompts:
- [[2026-11-07 Galaxy Incremental - Prompt - PHONE HUD fix (live game)]]
- [[2026-11-07 Galaxy Incremental - Tycoon pad fix + HUD art (side chips, LUMI panel)]] (Message for Claude Code, Overhead rank tag, Tutorial arrow)

Screens: `Progress/screens/2026-11-07-phone-hud/`.

The place's unpublished edit (GameConfig: the Mythic / Celestial badge ids) is kept: it's copied into the vault's GameConfig.lua, so a sync can't undo it.

## 1. Removed: the 3 step pads (UPGRADE / +BODY / UNLOCK)
They're gone from:
- MapConfig: `Boards.StepPads`;
- MapService: the builder, and its spot in the buy-pad clearance check;
- EconService: the stand-to-buy loop;
- MapClient: their faces + labels.

The BODIES board buttons are unchanged. The request handler keeps its name (`handleRequest`); the tycoon pad uses it.

## 2. The real tycoon button: the island buy pad (NextPad) is PRESSABLE
- **Server (EconService):** every 0.25 s, the island OWNER's root over their own NextPad disc (feet on it) = one press on STEP-ON only. The disc dips, then 0.12 s later the SAME `BuyPad` the click uses (the server checks price + ownership).
- **No chain-buying:** if the next pad appears under you, you must step off and on again.
- **Can't pay:** once per step-on, the pad's Denied counter goes up; the client plays a soft no + a red flash + "NEED x".
- **Client (MapClient):** the disc sinks 0.25 studs in 0.12 s with a click, then the buy sound (the build VFX follow as before). The click on the pad still works.
- **The label:** sized in studs now (it shrinks with distance), seen within 30 studs.
- **Your own rank tag is hidden for you** (others still see it), so it never covers the pad's label.

**Tests** (a throwaway save):

| test | result |
|---|---|
| walk on with money | bought once |
| the next pad spawned UNDER the player, stood 2.5 s | no second buy |
| step off and on | bought again |
| no money | Denied 1 (once per step-on), no buy; off + on = 2 |
| a non-owner (my pad copied onto island 2) | nothing (no press, no denied) |

## 3. Phone HUD
**Cause:** phones got the PC HUD shrunk to 0.67, so texts were 3-12 px. The HUD sat under Roblox's own buttons (it used the whole screen). The billboards were sized in pixels, so on a 360-px phone they were giant.

**Emulator** (Studio only; UIKit): Workspace `TestDevice` = `android` (800x360) / `se` (667x375) / `pro14` (852x393 + notch insets) / `ipad` (1180x820) / `pc` (1920x1080).
- It lays every HUD out in that device's safe area.
- It draws a mock of Roblox's top-left buttons.
- A device bigger than the window is drawn smaller; the layout still uses its own size.
- The old copy-pasted 667x375 frame in 12 scripts is replaced by `Kit.testRoot` / `Kit.viewport` / `Kit.topbar`.

**Real devices:**
- Every HUD ScreenGui uses `DeviceSafeInsets` (no notch); the layouts measure the safe area.
- Roblox's buttons come from `GuiService.TopbarInset`.

**The phone arrangement** (short side < 500):
- **Top centre:** the stardust counter + shards; NEXT under it; the event as a 28 px pill under NEXT (no more banner mid-screen).
- **Top left, UNDER Roblox's buttons:** LVL, then IGNITION.
  - The prompt said "one row". Side by side they ran into the counter on 667 px, so they're stacked.
  - The galaxy-lit bar and the 10 px XP / SHARDS captions are hidden on phones.
- **The chip column:** under them.
- **LUMI's compact card:** above the hotbar.
- **Hotbar:** no key letters on touch; the Q gear gets a soft glow (it read as an empty slot).
- **Tablets** (touch, short side >= 500) never scale under 1, so their texts stay >= 14. A PC window keeps its old minimum (at 1 a small window ran into itself).

**Built for the coming art (owner):**
- **`Kit.hudChip`:** a hotbar-style diamond icon tile + a text pill that grows with its text. Used by GIFT, FRIENDS / INVITE, GROUP, PREMIUM, BOOSTS, in ONE UIListLayout column.
  - The INVITE button is now the friends chip itself (it was clipped).
  - Phone labels are short: 4:48 / INVITE / JOIN +10% / PREMIUM / x3.45.
- **LUMI's card:** UIListLayouts: [portrait] [STEP + name (PC), the goal, the bar + count] [reward (PC)] [HIDE / SKIP]. Its plate follows the content. Phone: compact, with two small icon buttons (– and »).
- The U4 / U5 images only need to go into `Kit.hudChip` and the card.

**Billboards:**
- The buy-pad label and the rank tag are sized in studs (`Kit.studsBillboard`).
- The "STONE ISLAND" title in the owner's screenshot was the island buy pad's label: now studs + MaxDistance 30.

**Tools/UIAudit** (`tools/UIAudit.lua`, in the place as `ReplicatedStorage.Tools.UIAudit`, master in `Roblox Playbook/Tools/`). It checks:
- overlaps between HUD components;
- text over text inside one;
- text under 14 px;
- clipped text;
- anything outside the safe area or under Roblox's buttons.

Decorations that break out on purpose (sparkles, glows) are marked AllowOverlap.

**UIAudit, fresh save, LUMI step 1, a test 2x event running:**

| device | before | after |
|---|---|---|
| Android 800x360 | OVERLAP 4, SMALL 38 (3-12 px), UNSAFE 1 (LVL under Roblox's buttons) | CLEAN (twice) |
| iPhone SE 667x375 | - | CLEAN (twice) |
| iPhone 14 Pro 852x393 (notch) | - | CLEAN (twice) |
| iPad 1180x820 | (first after-run: SMALL 8 + an overlap: the PC texts at 0.92; fixed) | CLEAN |
| PC 1920x1080 | - | CLEAN |

**Before screenshots:** only Android (the emulator was built in this job; the live layout was measured on Android before any change). The owner's own phone screenshots are the other "before".

## 4. Overhead rank tag
- **ONE compact tag:** the DisplayName, then one row: the rank plate with the Supernova count inside it ("NOVA IV  x25") and the VIP chip attached to its right end (+ the Forge collector title under it, if any).
- **Size:** in STUDS (~4.5 wide, max 5.5), so it stays the avatar's size at any zoom.
- **Visibility:** centred 2.5 studs over the head, MaxDistance 60, fading out closer than 6 studs. Your own is hidden for you.
- **Shots:** 15 and 40 studs (own tag switched on for the test only).
- **Not done:** screenshots next to another player (Studio runs one).

## 5. Tutorial trail pointed at the board's feet
- **Cause:** the floor trail ran toward the button's ground point (under the board) and stopped 5 studs short.
- **Fix:**
  - The board target also gives the face's normal.
  - The trail now ends at the free spot 6 studs in FRONT of the face.
  - Within 12 studs of the button there's no trail: the arrow + ring sit on the button itself (they were already placed on the button's real spot on the tilted face).
- **Measured:** from the island spawn, the nearest trail arrow is 19 studs in front of the BODIES face line (never under it). 9 studs from the board: 0 trail arrows.
- **Not walked:** every LUMI step one by one.

## Left / flags
1. **2-player tests:** a real 2-client test (the pad, the tags) was not possible in Studio here. Please try Test > Clients and Servers with 2 players.
2. **Art:** the U4 / U5 art isn't in yet (the layout is ready for it).
3. **Phone windows** (UPGRADES, TREE...) weren't re-checked in this job; they were fixed on 7 Nov (UI corners).
4. **Other islands' plates:** the island plate over each island (owner name + rank, read from the plaza) is still pixel-sized (that's for reading it from far away).

## 6. HUD ART in (owner's U4 + U5, `Kit.HudArt`)
**Left column:**
- GIFT, FRIENDS, PREMIUM and BOOSTS use the chip images; the friends chip has the green INVITE button (hud_btn_green) beside it.
- Text sits in the pill's dark inside: white with a black stroke; phones get short values.
- **GROUP** (116787686626945) still FAILS to load (moderation?): it keeps the drawn chip until its art loads (the column checks at start).

**LUMI panel:** hud_lumi_panel with LUMI in the ring; the goal line; hud_bar_track + hud_bar_fill (the progress); the counter; hud_btn_close (hide) + hud_btn_skip on the top-right rim. PC also has hud_tag_step (STEP x/20) on the rim and hud_slot_reward (+1 / +BONUS).

**9-slicing is done by hand** (`Kit.slice3`: left / middle / right cut with ImageRectOffset).
- Roblox's own Slice with a small SliceScale drew the art's corners almost full size and squeezed the chip's diamond and the panel's ring.
- The SliceCenters from the table are used as the cut lines. The stored sizes were checked: the same as the files, except the panel (1022x283).
- **The chips are cut through the pill's middle**, so the pill grows with its text. At the art's fixed size the pill only fitted ~4 characters.

**UIAudit with the art:** Android, SE, 14 Pro, iPad, PC all **CLEAN** (`11-` to `15-art-*.jpg`).
