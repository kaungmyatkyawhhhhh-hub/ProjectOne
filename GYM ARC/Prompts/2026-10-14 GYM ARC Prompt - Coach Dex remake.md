---
date: 2026-10-14
tags: [gymarc, prompt, npc]
status: Coach Dex done (15 Oct)
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Coach Dex remake (14 Oct)

```text
COACH DEX: remake him in the style of a big "shopkeeper bodybuilder" NPC (reference: a huge, smooth-muscled NPC leaning on a counter, serious face). Build our OWN version; don't use or copy another game's model. Save to Obsidian first.

1. BODY
   - Use our muscle mesh system at the MAX / Mass Monster stage on every group (huge traps, shoulders, chest, arms, forearms), smooth shaded, so he's clearly the strongest-looking person in the gym.
   - Skin: a warm brown tone with good contrast (not flat orange). Shirtless, or a tight black tank with "COACH" in plain text (no brands).
   - Head: short fade/buzz hair or bald, stern confident face (thick brows, slight frown or smirk). No default blank face.
   - Slightly bigger scale than players (about 1.15x) so he reads as the boss.

2. POSE + ANIMATION (this is what makes it look good)
   - He stands behind a counter/desk at his spot (Coach Desk or the front desk), LEANING forward on it with both forearms/fists on the counter, shoulders up, like he's watching the gym.
   - Idle loop: slow breathing (chest/shoulders rise), occasional head turn to look at the nearest player, and every ~10s a short flex or knuckle crack.
   - When a player comes close (8 studs): he looks at them and plays a quick nod. On talk: a pointing/"listen up" gesture.
   - Anchor him (no physics), and turn off collisions on his accessories.

3. HIS SPOT
   - A proper counter/booth matching the gym (dark wood + metal, a few props: protein tub, shaker, clipboard, whistle). A gold name sign above: "COACH DEX". The same ProximityPrompt style as the rest of the game.
   - Lighting: one warm spotlight on him so he stands out.

4. CHECKS
   - No clipping between his arms and the counter. Looks right from the front and at an angle. Follows the culling/LOD rules (far away = no animation).
   - Re-render his portrait for the tutorial dialog box from the new model (head and shoulders).

Screenshots: front, 3/4 angle, and a player talking to him, in screenshots/coach_dex/. Commit, update PROGRESS.md and Obsidian.
```

Correction, sent right after:

```text
COACH DEX - correction to section 2 (pose + animation):
- He always plays a slight idle loop while leaning on the counter (breathing, small weight shifts, shoulders moving). He is never fully still.
- Head tracking: when the nearest player is within 15 studs, his head (and a little of the upper torso) smoothly turns to stare at that player and follows them as they move.
  - Do it client-side (each player sees him looking at themselves) by rotating the Neck Motor6D C0 (and Waist a bit), lerped every frame for smooth movement.
  - Clamp the turn to about 70 degrees left/right and 30 up/down so it never looks broken.
  - When the player leaves the 15 stud radius, ease his head back to forward over ~0.5s.
- Keep the nod when you get close and the pointing gesture when you talk to him.
```
