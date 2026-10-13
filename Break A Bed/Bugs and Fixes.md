# Break A Bed: Bugs and Fixes

#break-a-bed #bugs

Back to [[Break A Bed/Project Overview|Project Overview]].

## Fixed #done
- **2026-10-10: "I don't see anything in Studio."** The scripts were only files on the PC and hadn't been put into Studio yet. Also, the beds only appear after pressing **Play**, because they're built in code. Fix: Claude added the scripts to the place through the Studio MCP.
- **2026-10-10: Roblox Studio MCP didn't load in Claude Code.** It was only set up for sessions started in `C:\Users\USER`. Fix: added it for all folders (`claude mcp add --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`). Claude Code needs a restart after adding an MCP server.
- **2026-10-10: Building the place file failed** with "Failed to deserialize JSON". Rojo needs part positions written as `"CFrame": { "CFrame": { position, orientation } }`.
- **2026-10-10: Broken glowing beds kept sparkling** while their pieces flew. Fix: sparkles are switched off when a bed breaks.
- **2026-10-10: Rebirth button could get stuck** after a failed rebirth. Fix: the button is re-enabled after every attempt. (First version, since replaced.)
- **2026-10-10: Karate-chop arm didn't move** ("C0 is read only"). Roblox characters now use AnimationConstraint joints, which can't be moved through C0. Fix: the chop is added on top of the joint's animation every frame (`Transform`), which works on old and new rigs.
- **2026-10-10: Bed health panel covered the stats** on small screens. Fix: moved it to the bottom above the EXIT button, and aimed the camera a little lower.
- **2026-10-10: The floating name tag blocked the view** in break mode. Fix: it hides while you're chopping.
- **2026-10-10: Level could get out of sync** if Strength was changed directly (e.g. from the command bar). Fix: the server always works Level out from Strength.
- **2026-10-10: Terrain covered the floors.** Roblox draws terrain about 2 studs above where it's filled, so the dirt hid the plaza and path tiles. Fix: all terrain fills are sunk 2 studs.

- **2026-10-10: "BUY" on the upgrade pads was sideways.** Fix: the pads are turned so their painted text reads upright when you walk toward the boards (the same trick now orients the floor numbers on the bed tiles).
- **2026-10-10: Floor numbers used huge text canvases** (a whole tile each), which risks Roblox's budget for surface text. Fix: each number now sits on its own small patch.

- **2026-10-10: Group Reward panel showed blank** (its text and buttons drew behind the dark background). The game's screen UI layers everything by one global ZIndex. Fix: everything inside the panel gets a higher ZIndex than the panel itself.

- **2026-10-12: The spin wheel turned square** with the new UI. Outlines used sharp corners everywhere, which also drew the round wheel as a square. Fix: outlines use round joins again; corners stay sharp because they're 3 px.
- **2026-10-12: Windows were taller than a laptop screen** (the shop and spin wheel went off the top and bottom). Fix: every window shrinks to fit the screen when it opens.
- **2026-10-12: Free Gifts button sat on top of the group reward button.** Its position used a screen-fit scale that hadn't updated yet. Fix: both buttons use the same scale.
- **2026-10-12: "Maximum event re-entrancy depth" warnings** from the new text shadows. The shadow copied the label's size every time a layout moved it. Fix: it only copies when something real changed.
- **2026-10-12: The new shop covered the side buttons on small screens.** With the category icons outside it, it was wider than the gap between the left and right buttons. Fix: every window also shrinks to fit the screen's width (leaving room for the side buttons).
- **2026-10-12: Boosts / category icons scrolled to the wrong place.** The scroll was worked out while the window was still growing. Fix: it scrolls after the window opens, using on-screen pixels.
- **2026-10-13: Exclusive Chest screen said "+$0 Cash every 15 min!"** on a new save. The amount was only set when opened through one function. Fix: it's set on build, on every open and on each new bed (40 breaks, at least $1,000, same as the payout).
- **2026-10-13: Right squares taller than a short PC window** (6 squares with Quests). Fix: the column shrinks to fit the screen height.
- **2026-10-13: Banners hid behind open windows.** Fix: the banner layer draws in front, like toasts.
- **2026-10-13: Favorite popup never appeared.** An always-visible empty HUD frame named "Offer" counted as an open window. Fix: only real windows ("...Panel", "...Popup") count.
- **2026-10-13: Toasts hid behind open windows** (e.g. a CODES result in Settings). Fix: the toast layer draws in front of windows.
- **2026-10-13: Shop / Boosts far above the stats on tall screens.** The buttons were placed from the top and the stats from the bottom, so the gap grew with the screen. Fix: one LeftColumn holds both.
- **2026-10-13: Right squares covered the jump button on phones.** Fix: they stop 20 px above it and use 2 columns when needed.
- **2026-10-12: AUTO switch showed while training.** The shop refreshes it for every pass owner. Fix: while training, the break panel keeps it hidden (the pass is for beds only).
- **2026-10-12: Gift card glows didn't show.** The `fx-glow` picture is too soft to show past a card's edge, and the Free Gift! glow drew on top of the button. Fix: outer glows are three soft outlines around the card / bar / button, placed under the button.
- **2026-10-12: Aura ground ring floated at the feet mid-jump.** The floor check only looked 6 studs below the hips. Fix: a longer check, and the ring hides if no floor is found.
- **2026-10-12: "Out of local registers" in GameClient** (Luau allows 200 locals in one scope). Fix: the Settings block is in its own `do ... end`. Put new top-level code in blocks or modules.
- **2026-10-12: Aura Walk Speed was one star behind** (it was applied before the star count updated). Fix: the stars are set first, then Walk Speed is re-applied.
- **2026-10-12: Exclusive Chest light cone was invisible.** Beam attachments placed with WorldCFrame before they had a parent ended up twice as far away; and a vertical Beam's width runs along the attachments' Y axis, so it had no width. Fix: parent first, then turn the attachments so their Y axis is flat.
- **2026-10-12: Bloom washed out the white floors** with the note's Threshold 0.92. Fix: Threshold 1.5, so only neon and lights glow.
- **2026-10-12: Big centre texts stacked** when beds broke quickly. Fix: a new one replaces the one on screen.
- **2026-10-12: Spin wheel slices and lines didn't line up.** They were drawn from many separate frames. Fix: one picture (`wheel-base.png`) for slices, lines, rim and hub; the landing angle is worked out from the same 45° slices, so it always stops on the server's prize.
- **2026-10-12: Boost timer text went outside its box.** Fix: the pill grows to fit its text (AutomaticSize + a list layout + padding).
- **2026-10-12: "Level bar stays empty".** The fill code worked, but the owner had just reached Level 116, so progress through that level was about 0%. The bar now always shows a sliver once there's any progress, and fills / flashes on level up.
- **2026-10-12: Exclusive Chest rune rings didn't show.** The spawn paving sits 0.29 studs above the ground, so the rings were buried. Fix: raised them above it.
- **2026-10-12: Green text drew a green shadow.** Text with a coloured word ("**x2** STRENGTH") copied the colour into its drop shadow. Fix: those labels use only the dark outline.

## Good to know
- Studio screenshots taken through the MCP don't show floating text (damage numbers, CRITICAL!) or the guide's yellow arrow. They're still there in the game; check them by playing.
- In the phone emulator, the MCP's mouse clicks miss buttons near the top (it doesn't count the phone's notch). Test phone buttons by hand.
- Changing a script's text from the MCP's `execute_luau` (`.Source = ...`) doesn't reach Play mode if that script is open in a Studio editor tab (the tab's text wins). Use the MCP's edit tool for open scripts. (Found 2026-10-12 when `StudioFreshSave` didn't switch on.)
- Test purchases in Studio: `ServerStorage.StudioTestReceipt` (made only in Studio) runs a fake purchase through the real purchase code.
- "Future" lighting (`Lighting.Technology`) and 3D grass (`Terrain.Decoration`): current Studio removed both settings (checked 2026-10-11), so there is nothing to switch on.
- The Studio MCP's `execute_luau` tool can't parse some newer Luau syntax (`..=`, `for _, x in tbl do`). Use `ipairs` and `x = x .. y` in snippets run that way. The game scripts themselves are fine.
- The tool's mouse clicks only take screen coordinates for 3D objects, not part names.
- The spawn shield bubble (ForceField) is switched off by `Environment` (SpawnLocation.Duration = 0).

## Open
- None right now. (The old built-in sounds were replaced with Creator Store sounds, all checked loading.)

## Bed didn't come back after spam-breaking (2026-10-11) #bugs
- **What happened:** sometimes, after breaking the same bed quickly over and over, it stayed invisible (or squished/sunk).
- **Cause:** during the short "blink" and the hit shake, the game remembered the bed's original look and position in a kind of list Roblox is allowed to clear by itself (a weak table). Under spam it got cleared mid-blink, so the bed was never un-hidden, and the next break saved "invisible" as its normal look.
- **Fix:** hiding no longer needs to remember anything (it uses a see-through switch that's just turned off again). Everything else is kept in normal lists. Safety checks: every second the game makes sure a bed that isn't blinking is visible and in place, and the server replaces a missing bed right away and re-checks every 5 seconds.
- **Tested:** 220 breaks in a row, never stuck. A deleted bed came back in under half a second.

## Pond had no water, trails looked blotchy (2026-10-11) #bugs
- **Cause:** Roblox's terrain "fill" can't put water where there's already sand or dirt, and diagonal trails only partly covered each 4-stud ground block, so the grass stayed.
- **Fix:** the pond is now written block by block (exact water, sloping sandy shore). Dirt trails were swapped for stepping stones, which look neater.

## Custom prompt showed two empty white boxes (2026-10-11) #bugs #done
- The custom-styled "Break" prompt drew only two blank white boxes in the real game (no key, no text). Fixed by removing it: every prompt is Roblox's default style again (E, "Break", bed name).

## 2026-10-11: VIP post did nothing #bugs #done
- **Cause:** the VIP lounge was moved and made bigger in Studio, but the post still remembered its old spot, so the game thought you were never standing on its pad.
- **Fix:** the server now measures the post and the lounge from the real parts every time the game starts, so moving it again keeps working.

## 2026-10-11: VIP door didn't open the VIP pass #bugs #done
- **Cause:** touching a solid wall doesn't always count as a "touch" in Roblox. Also, Roblox never shows the window to someone who already owns VIP (like the owner), so it can only be seen on a non-VIP account.
- **Fix:** the game checks every 0.1 s if a non-VIP is standing at the door and opens the VIP pass window (at most once every 5 s).


## 2026-10-13: guide beam went through the path fence #bugs #done
- **What happened:** after punching the Straw Post, the guide's beam pointed in a straight line to the Cardboard Bed, right through the path fence. A scripted new player walked into the fence and got stuck; on PC it slid along it for 9 s.
- **Fix:** when you and the target are on different sides of the fence, the beam leads to just past the arch first, then to the target. The same goes for every arrow (next bed, newly affordable post, Starter Quests).

## 2026-10-13: wall after bed 10 in the first 10 minutes #bugs #done
- **What happened:** in the 12-minute test, nothing new came for 158 s after the Diamond Bed (bed 10). A player who doesn't grind beds for cash couldn't afford the Iron Post ($230K, then $140K) until bed 11, and bed 11 needed 310K Strength with the Stone Post.
- **Cause:** the Starter Quest rewards (x2 Strength, cash, the aura) make players 2–3 minutes faster, which pulled this old wall into the first 10 minutes. With $140K it only just fitted (about $142K after bed 10), so a bit less crit luck missed it.
- **Fix:** re-tuned with the quests in the model; Iron Post $100K. The final 12-minute run's longest wait was 56 s.

## 2026-10-13: training combo counter hidden #bugs #done
- **What happened:** the combo counter floated over the post, but on PC the training camera puts the post top right behind the next-bed bar, and screen UI always covers world labels.
- **Fix:** the counter is in the HUD now, where the click hint was (just above the training panel; phones: bottom centre).

## 2026-10-13: Starter Quest 5 paid too much #bugs #done
- "Spin the wheel" paid 10 breaks of the best bed: $36K at the Hospital Bed, enough to buy the Brick and Stone posts at once. Now 2 breaks (at least $500).

## 2026-10-13: (testing) MCP screenshots freeze the camera #bugs
- Studio MCP's screen capture during a playtest leaves the camera on Scriptable. The view stops following the player, and prompts (Break / Train) stop showing, so a test bot "can't" press E. Not a game bug. After a screenshot, set `workspace.CurrentCamera.CameraType = Enum.CameraType.Custom` (only when not breaking or training).
- Studio's "Stop" counts as a normal leave (no Soft Shutdown save). To test a Soft Shutdown rejoin, run `ServerStorage.StudioSoftShutdown:Invoke()` first.

## 2026-10-13: tracker pill under Roblox's top bar on phones #bugs #done
- On the Galaxy A06 the new pill sat 45 px from the top, inside Roblox's 58 px top bar. Now it's always at least 4 px under the top bar. Its row also got taller (the thin bar hugs the bottom edge), because on a 32 px phone pill the text was tiny.

## 2026-10-13: click hint said "nil TO PUNCH 2x FASTER!" #bugs #done
- Moving the Starter Quest card into the pill removed the line that set TAP/CLICK, which the click hint also used. Put back. Found in the phone test before publishing.

## 2026-10-13: To Bed didn't move the player (first try) #bugs #done
- Server error "attempt to compare number <= Instance": the Strength stat is an object, so the check needed `.Value`. Fixed; every later teleport landed exactly on the bed's stand point.

## 2026-10-13: Starter Quest showed the old goal for a second #bugs #done
- When two goals finished less than 4 s apart (gift claim, then the spin), the first one's safety timer brought back "Spin the wheel 1/1" for a moment. Each finished goal now has its own timer. (The old card had the same bug.)

## 2026-10-13: GameClient over Luau's 200-locals limit #bugs #done
- Adding To Bed next to SPAWN gave "Out of local registers ... exceeded limit 200": the whole client script failed, so there was no HUD. Locals in a top-level `do` block count too. Fix: To Bed's parts live in one table, and its wiring runs inside its own function. `GameClient` is right at the limit, so new HUD pieces should go in their own module or function.
