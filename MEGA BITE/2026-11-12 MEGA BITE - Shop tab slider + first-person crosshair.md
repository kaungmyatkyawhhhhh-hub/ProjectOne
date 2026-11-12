# MEGA BITE - Shop tab slider + first-person crosshair (12 Nov 2026)

## 1. The Shop's green tab pill slides (owner 14:15: "the green thing should go smoothly, rn when i click or scroll it goes immediately")
- Before: each tab switched its own lime background on/off, so the pill jumped.
- `UIKit.K.Tabs` rebuilt: ONE lime pill (`Tabs.Track.Slider`) under the tabs; the tabs sit in an inner `Row` that holds the list layout. On a pick the pill's position AND width ease together, 0.34 s Quint Out (no overshoot); the picked tab's icon gives a small tilt; label fade 0.18 s. `Select(key, true)` snaps (the Shop opening on Featured).
- Things that broke it while building (kept as lessons):
  - a Back (overshoot) ease and a "stretch" pushed the pill ~25 px past the capsule's ends: removed;
  - the pill inside an AutomaticSize capsule made the capsule grow during the stretch, which fired the "capsule resized: snap" hook and cancelled the slide: the pill now lives in a scale-sized Track (doesn't count toward automatic size) and only the Row's resize snaps it, never mid-slide;
  - a UIScale "hop" on a tab icon changed the row's LAYOUT width (UIScale counts in layouts), which also snapped it: now a Rotation tilt.
- `MB_StoreUI`: clicking a tab scrolls the list with a tween, and the scroll-follow re-picked tabs along the way (Passes ended on Skins). The follow now pauses for 0.5 s after a tab click.
- Measured in Play: Featured -> Passes 5 -> 302 px over ~0.2-0.35 s, inside the 448 px capsule; scrolling also slides it.
- Old: `ServerStorage.UIKit_preTabSlide_12Nov`, `MB_StoreUI_preTabSlide_12Nov`.

## 2. First person: locked centre cursor + "+" crosshair (owner 14:16: "the cursor should be locked in the middle and like the + in the center like minecraft cursor")
- `MB_Swim`: when the camera is fully inside the head (firstPerson), PC: `MouseBehavior = LockCenter`, `MouseIconEnabled = false`, and mouse movement looks around without holding right-click (Minecraft feel; steering is camera-relative so the mouse steers).
- A white "+" (22 px, 3 px bars, thin navy outline so it reads on bright water) in the screen centre (`MB_Crosshair`, pops in 0.22 s Back). Phones/tablets get the "+" only.
- The cursor comes back: while a window is open (Shop/Index/Settings), during cutscenes (`camOverride`), while ALT is held (to click the HUD), and as soon as you scroll out. Releasing right-click no longer unlocks first person.
- First time per session in first person (PC): a hint under the "+" for 3.5 s: "Hold ALT for cursor · scroll out to leave".
- `Bus.State.firstPerson` is now published for other scripts.
- Checked in Play: zoomed in -> LockCenter, icon hidden, "+" and hint shown; scrolled out -> Default, icon back, "+" hidden. No script errors. Not checked: ALT held, opening a window from first person, a phone.
- Old: `ServerStorage.MB_Swim_preCrosshair_12Nov`.

## 3. Fix: "when i click play i dont spawn in" (owner 14:31)
- Not a script error. `MB_Data.Load` (session lock) found a lock left by an EARLIER Studio test that never released it (a Play session froze and was force-stopped). It waits up to 25 s for the "other server", and every retry is an UpdateAsync on the same key (about one write per 6 s per key), so in practice the shark appeared only after ~60-70 s.
- Fix (`ServerStorage.MB_Data`, old copy `MB_Data_preStudioLock_12Nov`): in Studio, a lock whose job starts with "studio-" is taken at once. Live servers' locks (real JobIds) keep the full wait, and live servers still wait on any lock as before.
- Checked: Play right after a stop spawns the shark in 0.7 s at the saved Evo 7 / EXP. The save was never at risk (Evo 7, EXP 7,636 in the record).

## 4. Fish outlines sometimes missing (owner 14:40)
- `MB_FishClient` gave the outlines (F.Outlines = 18) to the nearest fish INCLUDING ones behind you, re-dealt them every 0.2 s by distance (outlines jumped between fish and blinked), and Roblox draws only ~31 Highlights at once (each pooled predator has one, PvP shields too).
- Now: only fish on screen compete, nearest first; a fish keeps its outline while it stays chosen; up to 24 outlines, never more than 30 minus the other enabled Highlights (tracked live). Lock / "=" tags follow the same slots. Checked in Play: 13 outlined, all on screen, no errors. Old: `MB_FishClient_preOutlines_12Nov`.

## 5. Ability cancelled by a bite (owner 14:40: "when ability and the shark bite at the same time, the ability dont work")
- Abilities are their clip: animation, VFX and the one sound all run from markers in it. A bite (BiteAt) restarted the body on the Bite clip (only Dart was protected) and cut the ability off, and shortened its busy time to 0.45 s.
- `MB_Swim`: while the ability clip is still the playing clip, bites and darts leave the animation alone (eating, EatPop/Gulp and the dart's push still happen). Checked: Megalodon Tidal Roar with bites at 0.2 / 0.45 / 0.75 s still spawned its VFX at 0.4-0.7 s. Old: `MB_Swim_preAbilityGuard_12Nov`.

## 6. Unlock celebration for the COMING NEXT column (owner 14:46 "tap reborn ui's are insane" -> 14:52 "ok start")
- Correction: the reference's padlocked teaser column ALREADY existed (UI v6, 11 Nov, `MB_HUD` "COMING NEXT": next ability with its shark, Fossilize at Megalodon, the PVP Red Trench door). The owner is a Megalodon, so only the PVP tile shows for them.
- The real gap vs Tap Reborn: reaching a feature made its tile silently vanish. Now (`MB_HUD`, old copy `MB_HUD_preUnlockFx_12Nov`) a frozen copy of the tile plays the moment:
  1. padlock rattles (5 swings, 0.37 s);
  2. it pops off (rises, spins, fades) with a glint ring (UIFx.BurstAt) + UIEquip chime; the grey icon fills with colour; the tile pops to 1.45x then settles at 1.2x; label "UNLOCKED!" in lime; a sheen;
  3. after 1 s it flies (0.42 s Quad In) into the button it unlocked (Ability / Fossilize), shrinking to 0.45x; UIPop + small glint ring; that button bumps 1.3x;
  4. the column's next tile pops in (Back 0.4 s).
- Waits for the evolve cutscene (camOverride) and any open window (cap 20 s), queues several unlocks (6 -> 7 = Tidal Roar, then Fossilize), never plays while the save loads in (Loaded) or on evolution going down (Fossilize, Studio [ ), off with Reduced Motion.
- Checked in Play with client-only Evo changes (server/save untouched): 1->2 Frenzy, 2->3 Torpedo (flight logged into the ability button), 3->4 Shark Sense, 4->7 two celebrations in a row; screenshot of the "UNLOCKED!" pop. No script errors.
