---
date: 2026-10-14
tags: [gymarc, prompt, skate, ui]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: skating speed, stamina bar, skate button (14 Oct)

```text
BUG: skating is slow when the player is big/tall. Skating should feel fast at every size.

1. Find why:
   - If skating uses LinearVelocity/BodyVelocity/VectorForce: is MaxForce fixed? Bigger players have more AssemblyMass, so a fixed force pushes them slower. Make the force scale with the character's AssemblyMass (or use LinearVelocity with ForceLimitsEnabled = false / a huge MaxForce) so speed is the same no matter the mass.
   - Does any size/muscle/weight system lower WalkSpeed or apply a "heavy" slowdown? That must NOT apply while skating.
   - Check friction (CustomPhysicalProperties) and HipHeight on big characters. The skateboard shouldn't scrape the ground.
2. Speed should scale UP a little with height so big players feel just as fast: skateSpeed = Config.Skate.BaseSpeed * (1 + 0.35 * (heightScale - 1)), capped at Config.Skate.MaxSpeed.
3. Acceleration and turning should also feel the same at every size (scale turn speed the same way).
4. The board (and any skate effects) should scale with the character's size so it doesn't look tiny under a giant.
5. Test at the smallest size, mid size, and 7'0" max with mass monster muscles: same feel, and measure the actual speed (studs/s) in each. Put the numbers in PROGRESS.md.

Commit, update PROGRESS.md and Obsidian.
```

```text
STAMINA BAR: only show it while exercising.

- Visible only while the player is on a machine (lifting, treadmill, anything that uses stamina) or during Auto Rep.
- Fade in over 0.2s when they sit on a machine, fade out over 0.4s about 1.5s after they leave. Use a tween on GroupTransparency (put it in a CanvasGroup), not by moving it.
- Also show it for 3s and then fade out when stamina changes while NOT exercising (drinking a shake, the Stamina Refill product, a trainer refill), so players see it fill up.
- While it's resting (stamina below max and not exercising) it stays hidden. It's fine that it refills in the background.
- The active boost icons that sat above the stamina bar must stay visible when the bar is hidden: keep them in their own spot at the bottom center, and don't let them jump when the bar appears.
- Nothing else that was positioned relative to the stamina bar should move when it shows or hides.

Test: walk around (no bar), sit on a machine (bar fades in), leave (fades out), drink a shake while walking (shows 3s). Phone and PC. Commit, update PROGRESS.md and Obsidian.
```

```text
SKATE BUTTON: make it easy to find. Right now it's a small button at the top right that nobody notices.

1. Position
   - Mobile: a round button just LEFT of the Roblox jump button, same size as the jump button, centered on the same height (work it out from TouchControlFrame.JumpButton's AbsolutePosition/Size, recalculate only when the screen size changes).
   - PC: bottom right above the hotbar area, with a key hint chip "Q" (bind Q to toggle skating; keep any existing key too).
   - Hidden while on a machine (REP/PUMP use that area then), during cutscenes and inside menus.
2. Look (final black + gold kit)
   - Graphite circle, gold 2px ring, a skateboard icon in the middle, small "SKATE" label under it.
   - When skating is ON: gold filled circle, dark icon, slow shine sweep, label "SKATING". Tap again to stop.
   - Press = UIScale 0.92 + bounce, click sound.
3. Make players notice it
   - First time a new player walks for 10s, show one hint bubble pointing at the button: "Tap to skate - get around faster!" (once per player, saved).
   - Add a step about it to the tutorial.
   - A short skate start effect (whoosh sound + small dust puff) so it feels good to use.
4. Remove the old skate button from the top right.

Test on phone 844x390, small phone 667x375 and PC: not covering the jump button, the thumbstick or anything else. Screenshot ON/OFF states. Commit, update PROGRESS.md and Obsidian.
```

```text
Skate button: use Downloads\gym_arc_ui_3d_icons\skate_button.png as the whole button (the circle, gold ring and background are in the image). Upload it to Myanmar Builders Club and find the ID with search_asset by exact name. Put it in a square ImageButton with no background or UIStroke. ON state (skating): keep the same image and add a gold UIStroke glow ring that pulses slowly plus the label "SKATING". OFF: label "SKATE".
```
