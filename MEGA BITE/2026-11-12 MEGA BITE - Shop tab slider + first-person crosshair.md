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
