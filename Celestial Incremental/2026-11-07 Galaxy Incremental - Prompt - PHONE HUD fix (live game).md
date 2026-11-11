---
date: 2026-11-07
tags: [galaxy, ui, mobile, prompt, claude-code, urgent]
---
# Galaxy Incremental: phone HUD is broken (owner phone screenshot, launch day, game is LIVE)

The owner's phone screenshot (landscape, 2x hour running) shows the whole HUD overlapping. Most Roblox players are on phones, so this is the top priority today.
Rules: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (PHONE LAYOUT, UI CORNERS), Playbook "UI deep dive".

```text
GALAXY INCREMENTAL – URGENT: THE PHONE HUD OVERLAPS EVERYWHERE. The game is LIVE (alpha since 9:00 AM MMT). Fix it today; screenshots attached by the owner. Test, then tell me; I publish. (The place also has an unpublished edit: GameConfig badge ids Mythic/Celestial; keep it.)

WHAT THE OWNER'S PHONE SHOWS (landscape):
1. Roblox's top-left buttons (logo, menu, chat, mic) sit ON TOP of the "2.9/8 LVL 1" chip. The IGNITION 0/4 chip is cut off under the LVL chip.
2. The stardust bar "46.4 +2/s" overlaps the island's world title "STONE ISLAND", and "NEXT: MOON · 80" sits on top of both.
3. The "2x STARDUST HOUR · 49:05 LEFT" banner is in the MIDDLE of the screen, over the world.
4. World billboards are giant and stack:
   - the step-pad labels "UNLOCK" / "UPGRADE" / "LOCKED";
   - the island title "STONE ISLAND";
   - the SPARK I rank tag.
   They cover the BODIES board and each other.
5. Left column: the INVITE button is clipped ("NVITI"). The JOIN GROUP / PREMIUM text is tiny.
6. The LUMI tutorial panel overlaps itself:
   - "LUMI" over "STEP 1/20";
   - HIDE over "SKIP (not advised)", which is cut off;
   - the +1 / +BONUS reward over the task text "UPGRADE your Asteroid".
   The hotbar cuts into the panel's bottom.
7. The hotbar shows an empty Q slot and the keyboard letters (U F T J G Q) on touch.

FIX (phone first, then check that PC is unchanged or better):
A) Safe area: every ScreenGui gets ScreenInsets = CoreUISafeInsets (or offsets from GuiService.TopbarInset), so nothing sits under Roblox's buttons. The top-left chips start right of / below them.
B) A real PHONE layout:
   - when the viewport's short side < 500 logical px: a UIScale from the viewport (min 0.75) + a phone-specific arrangement, not the PC layout shrunk;
   - top: currency bar + LVL/IGNITION in one row (never over each other);
   - "NEXT: ..." as a small line UNDER the currency bar;
   - the event banner becomes a compact pill under the top row (max ~28 px tall on phone), never in the screen centre;
   - left column: collapse GIFT / INVITE / GROUP / PREMIUM / BOOSTS into a short stack of icon chips (icon + short value), each tap opens its detail; nothing clipped;
   - hotbar: hide empty slots; hide the key letters on touch devices;
   - LUMI panel on phone: one compact card (portrait + task line + progress) above the hotbar, NOT overlapping it. HIDE / SKIP become small icon buttons in its corner. The reward chip goes on its own row or is dropped on phone. Build it with UIListLayout / UIPadding / AutomaticSize, not hand-placed offsets.
   - The centre of the screen (the character + the world in front) stays free.
C) World billboards:
   - size in studs (UDim2 scale), not pixels, so they shrink with distance;
   - MaxDistance: pad labels 30, island title 60;
   - only the pad the player is nearest to shows its full label; others show just a small icon/price;
   - the island title sits high above the island, not at screen height near the spawn, and smaller;
   - the rank tag stays small above the head.
   Nothing may cover a board face (FACECLEAR again from the spawn).
D) Text: nothing under 14 px on the smallest phone. Shorten labels on phone if needed.
E) UIAudit tool (Tools/UIAudit, run on the client): for each device size it lists:
   - any two visible HUD GuiObjects whose AbsolutePosition rects overlap (not parent/child, not marked AllowOverlap);
   - any TextLabel/TextButton whose real text size < 14 px or whose text is clipped (TextFits false);
   - anything outside the safe area.
   Run it with the device emulator on:
   - a small Android landscape (~800x360);
   - iPhone SE landscape;
   - iPhone 14 Pro landscape (notch);
   - iPad;
   - PC 1920x1080.
   It must be CLEAN on all 5.
F) Do it on a fresh save (TestFreshSave) during the 2x event (set a test event start 2 min from now in Studio only; don't change the real Events).

REPORT: before/after screenshots on all 5 device sizes (same spot as the owner's screenshot: the spawn of a fresh island, LUMI step 1, event running), the UIAudit output, and anything left. Don't publish.
```
