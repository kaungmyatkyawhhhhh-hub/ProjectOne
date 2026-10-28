---
date: 2026-10-28
tags: [speedarc, launch]
status: to do (owner)
---
# SPEED ARC - Launch Checklist (owner)

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

Everything you need to do before publishing the soft launch. Tick them off here.

## 1. Imports (Studio, into `ServerStorage/Meshes`)
- [x] All 25 meshes imported (28 Oct). They landed in Workspace; moved into `ServerStorage/Meshes`, hub / park / stadium rebuilt with them.
- [x] Fit checked: shoes, tee, shorts, bib OK. Worn items now sit outside the character (inside it, the tee did not draw).

## 2. Creator Hub (all in the GROUP that owns the game)
- [x] The place is in the group (group 33151111).
- [x] (28 Oct) 8 game passes + 5 developer products created, ids in `Config/Store`, all 13 checked with Roblox: names, prices and on-sale match. Exact prices were from [[2026-10-28 SPEED ARC Progress - 5 Store, passes, Starter Pack, Locker cosmetics|Progress 5]] -> send me the IDs.
- [x] Pass / product icons: **made** and uploaded; the in-game store shows them. (13 PNGs in `Downloads\speed_arc_models\icons\`, preview `Screenshots/models/icons/icon_sheet.png`). You approve, then add each one when you create its pass / product (in the group).
- [ ] **UI art kit (prompt 12, approved 28 Oct):** upload the 3 sheets in `Games/SpeedArc/ui_kit/sheets/` (`ui_buttons.png`, `ui_tiles.png`, `ui_icons.png`) to the NEW group (after prompt 13), then paste the 3 ids into `Config/UIArt.lua`. **Must be done before publishing**: with no ids the live game has no buttons/panels art.
- [x] Kit clothing: 8 templates uploaded, ids in the game (28 Oct). (If the place moves to the group later, re-upload them in the group and send the new ids.)
- [x] (28 Oct) 3 notification strings made in Creator Hub (`daily_ready`, `new_league`, `weekly_top`) - text in [[2026-10-28 SPEED ARC Progress - 4 First 15 minutes, daily, quests, social|Progress 4]].
- [ ] Open Cloud API key in Secrets (only when we wire the daily notification sender).
- [x] Music picked (APM library, licensed): Hub "Aim High" 1839850159, Park "Summer Memories" 9043824305, Stadium "No Time To Think (Long Perc)" 1837843290, Race "Battleground" 9048541013. Loudness measured and balanced. Listen and tell me if one is wrong.

## 3. Game page
- [ ] **Name (suggested, 28 Oct):** "+1 Speed Every Step: LIVE RACES"  (others: "+1 Speed Race vs Real Players", "SPEED ARC: +1 Speed Race"; "SPEED ARC" stays the brand on the logo and in the game)
- [ ] **Description (suggested, 28 Oct):** "+1 SPEED every step! Run, get faster and SMASH through walls. Every 3 minutes a LIVE RACE starts: race real players on the track, climb the podium and win the biggest prizes in the game (huge coins + 2x SPEED!). Collect shoes, trails and coaches, smash the last wall and GO PRO to new worlds: City Park and the Big Stadium. Quiet server? Runner bots fill the lanes, so a race always starts."
- [ ] **Icon + 3-5 thumbnails** (you make them): a wall smash (pieces flying, a big number), the candy spawn, the Coach Agency, a race start.
- [ ] **Genre:** Sports (subgenre: Racing / Simulator).
- [ ] **Age rating questionnaire:** no violence, no blood, no gambling (coach rolls are coins only, no Robux), no realistic people. Has in-experience purchases.
- [ ] **Devices:** phone, tablet, computer, console (the UI is touch-first; console not tested).
- [ ] **Social links:** a Roblox group + (optional) Discord / YouTube on the game page.
- [ ] **Max players:** 12 (6 lanes in the hub, 8 in the stadium).

## 4. Before you press Publish
- [ ] Remove the Studio test switches from Workspace (anything starting with `Test`, plus `FreshPlayer`) - they only work in Studio, but keep it clean.
- [ ] Studio: File > Save to Roblox, and a dated backup file (`SPEED ARC 2026-10-28.rbxl`).
- [ ] Game Settings > Security: API services ON (saves, leaderboards), HTTP OFF.
- [ ] Play once in a real server: your save loads, a race runs, the leaderboards fill after a minute.
- [ ] Phone test (below).

## 5. Phone test (what to send me)
1. Join on your phone. Press F9 isn't on phones: use a PC + phone together, or the Roblox app's **Settings > Performance stats** (shows FPS and memory).
2. Play 10 minutes (tutorial, a race, the Park if you can).
3. Send me: **FPS** in the hub, in a race and in the stadium; **memory (MB)**; anything that looked cut off, too small or overlapping; any button that was hard to tap.
4. On PC (Studio "Test" on a real server, or the live game): press **F9** > **Memory** tab > send the top 5 "Client" numbers, and **Script Performance** > the top 5 scripts.

## 6. Codes for launch
SPEEDARC (5 min coins), FIRSTRACE (a coach roll), RELEASE (10 min coins + a roll). Put them in the game description or your socials.

## After the 28 Oct pivot
- [ ] Rename the "Auto Train" pass to "Auto Run" in Creator Hub (same id 2058077302).
- [x] (prompt 11) Wall course + candy rebuild for City Park and Big Stadium.
- [x] (prompt 11) Pacing pass for steps and walls (`tools/step_pacing_sim.py`).
- [x] (prompt 11) Game page text written (section 3).
