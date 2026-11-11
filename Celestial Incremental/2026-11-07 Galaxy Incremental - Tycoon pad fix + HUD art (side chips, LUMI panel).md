---
date: 2026-11-07
tags: [galaxy, ui, art, chatgpt, prompt, claude-code, tycoon]
---
# Galaxy Incremental: the real tycoon pad, remove the extra pads, new HUD art (owner, 7 Nov, game live)

Owner (3 screenshots):
1. STAR DAIS pad: "tycoon button WHICH IS supposed to be pressable and not just clickable". So "step on the buttons" meant the EXISTING island buy pads (NextPad: STAR DAIS etc.), not new ones.
2. The UPGRADE / +BODY / UNLOCK floor pads: "buttons that i didnt even mention to put in, we dont need that". Remove them.
3. The left column chips (NEXT GIFT, INVITE, GROUP +10%, PREMIUM +10%, BOOSTS) and the LUMI tutorial panel "are ugly ... look more like placeholder UIs". The hotbar is the good one, so the new art matches the hotbar.

Hotbar style (the reference the owner likes):
- diamond tiles with a thick glossy coloured bevel rim (orange, grey, green, teal, violet, red), a dark navy inner, chunky glossy icons, small sparkles, a thick dark outline;
- the key letter is outside the tile.

## U4 - HUD side-chip set (ChatGPT, one try)
```text
Create ONE image, 1536x1024, a flat solid MAGENTA background (#FF00FF, no gradient, no shadow on it). Separate Roblox mobile game HUD pieces, each with wide magenta space around it, no overlap, NO text, NO numbers, NO letters anywhere. Style: chunky glossy Roblox simulator UI exactly like a hotbar of DIAMOND-shaped tiles with thick glossy bevelled coloured rims, a very dark navy-violet glossy inner, a thick dark outline, a small white highlight on the top edge, tiny sparkles. NOT a photo, NOT flat, no magenta in the art.
TOP ROW, five HUD CHIPS (each a horizontal pill 4:1, the left end is a DIAMOND tile that overlaps the pill like a badge; the pill's inside is EMPTY dark navy for text added in game):
 1. GOLD rim chip, diamond holds a glossy purple GIFT BOX with a gold ribbon.
 2. GREEN rim chip, diamond holds two cute round friend heads (simple, faceless smiles) with a small plus sign shape.
 3. VIOLET rim chip, diamond holds a violet SHIELD with a gold star (group).
 4. CYAN-GOLD rim chip, diamond holds a gold CROWN with a cyan gem.
 5. ORANGE rim chip, diamond holds an orange-yellow LIGHTNING BOLT.
BOTTOM ROW: 6. a separate small glossy GREEN rounded button (3:1), empty. 7. the same button in BLUE. 8. the same in RED. 9. a small GOLD pill tag (3:1), empty. 10. one empty chip pill WITHOUT a diamond (4:1, violet rim), for spare use.
```

## U5 - LUMI tutorial panel (ChatGPT, one try)
```text
Create ONE image, 1536x1024, a flat solid MAGENTA background (#FF00FF, no gradient). Separate Roblox mobile game UI pieces, each with wide magenta space around it, no overlap, NO text, NO numbers, NO letters anywhere. Same style as a glossy Roblox simulator hotbar: thick glossy bevelled rims, very dark navy-violet glossy insides, thick dark outline, white top highlight, tiny gold sparkles. NOT a photo, no magenta in the art.
TOP: one wide TUTORIAL PANEL frame (4:1): a dark navy-violet glossy panel with a thick GOLD-VIOLET bevel rim; on its LEFT end a big round PORTRAIT RING (gold with small stars, an empty dark inside, it sticks out above and below the panel a little like a badge); the rest of the panel is EMPTY for text.
MIDDLE ROW: 1. a progress BAR track (10:1, dark inset groove with a gold rim, empty), 2. a progress bar FILL piece (10:1, glossy bright green with a white highlight stripe), 3. a small glossy round CLOSE button, blue, with a simple down-chevron shape, 4. a small glossy round SKIP button, red, with a simple double-arrow shape.
BOTTOM ROW: 5. a small gold STEP pill tag (3:1, empty), 6. a small square REWARD slot (dark inside, cyan-gold rim, tiny sparkles).
```
Claude cuts: magenta key, alpha cleanup, 9-slice SliceCenter for the chip pill, panel, bar track/fill and buttons, then uploads to P&L Studios XP and gives Claude Code the ids.

## Message for Claude Code (now; it can run alongside the phone HUD fix)
```text
GALAXY INCREMENTAL – OWNER CORRECTIONS (the game is LIVE). Do these together with the PHONE HUD prompt. Don't publish; I publish.

1) REMOVE the 3 step pads (UPGRADE / +BODY / UNLOCK in front of BODIES). The owner never asked for them ("we dont need that buttons"). Remove:
   - MapConfig.Boards.StepPads;
   - the pads + their labels;
   - EconService's stand-to-buy loop for them;
   - their audit entries.
   The BODIES board buttons stay exactly as before.
2) THE REAL TYCOON BUTTON = the island buy pad (NextPad: the glowing disc with "STAR DAIS · 60.0K · x1.15 STARDUST" etc.). It's click-only now; the owner wants it PRESSABLE by walking onto it, like every tycoon.
   - Server: when the island OWNER's character stands on the NextPad disc (root over the disc, feet on it; check every 0.25 s; or Touched + a position check), buy it once through the SAME handler the click uses (server checks price + ownership). One buy per press: after a buy the next pad appears (it already does); a new buy needs the player to step OFF and ON again (no accidental chain-buying of the next pad if it spawns under them).
   - Can't afford: a soft "no" sound + red flash + "NEED <amount>" once per step-on, nothing else.
   - Feel: the disc presses down 0.25 studs (0.12 s) with a click sound, then the buy sound + the existing build VFX.
   - Keep the click as a backup.
   - Only the owner's own island pad reacts.
   - Label: keep "STAR DAIS / price / x1.15 STARDUST" above it. The player's own name/rank tag ("FLARE I · 1 · VIP") must not cover it: hide your OWN overhead tag for yourself (others still see it), or put the pad label higher.
   - Test: walk on with enough money (buys once, the next pad appears, doesn't auto-buy it), walk on without money, a non-owner on your pad (nothing), phone.
3) LEFT COLUMN + LUMI PANEL look like placeholders (owner). New art is coming (U4 side chips, U5 LUMI panel, matching the hotbar). For now, do ONLY the layout from the phone prompt with UIListLayout / AutomaticSize, so the art can drop in: chip = diamond icon tile + pill with text; LUMI = portrait ring + text + bar + 2 small icon buttons. I'll send the asset ids + 9-slice SliceCenters when they're processed.
REPORT: what was removed, the pad test results (+ a short clip or screenshots), phone + PC screenshots.
```

## Overhead rank tag (owner asked "u think its good?", 7 Nov): not yet
What's wrong in the owner's 2 screenshots:
- **Wrong size scaling (owner, 7 Nov):** "it becomes big when i zoom out and when i zoom in its tiny". The BillboardGui is sized in pixels (Offset), so it stays the same size on screen: zoomed out it dwarfs the avatar, zoomed in it shrinks next to the avatar. It must be sized in studs (Scale) so it stays the same size as the avatar.
- **Three loose pieces** (FLARE IV plate, "✦3", VIP pill) floating with gaps; it reads as clutter, not one tag.
- **"✦3" means nothing to a new player:** is it Supernovas? A level?
- **No player name**, so you can't tell who it is.
- **Sits too low:** it overlaps the head instead of floating above it.

```text
OVERHEAD TAG (add to the current job): make the rank tag ONE compact tag above the head.
- Layout (top to bottom): the DisplayName (small, white, black outline), then ONE row: the rank plate (FLARE IV) with the Supernova count INSIDE the plate's right end as a small "x3", and the VIP chip attached to the plate's right edge (only if VIP).
- Size in studs (UDim2 scale): about 4.5 studs wide total, never wider than ~2x the avatar. StudsOffsetWorldSpace about head + 2.5, so it never touches the head.
- MaxDistance 60. Fades out under 6 studs from your camera. Your OWN tag is hidden for you.
- Phone: the same tag must stay readable at 15 studs and not cover boards (UIAudit / FACECLEAR from the spawn).
- Screenshots: close, 15 studs, 40 studs, on PC + phone, next to another player.
```

## Tutorial arrow points at the board's feet (owner, 7 Nov)
Owner: "the arrow that points to the board's button points to the boards feet cuz it cant go up".
- **Cause:** the guide's world arrow/trail follows the FLOOR and ends where the board stands on the ground. The button is up on the tilted board face (a SurfaceGui button), so the arrow never reaches it.

```text
TUTORIAL ARROW TO BOARD BUTTONS (add to the current job):
- For any LUMI step whose target is a button on a 3D board (SurfaceGui), work out the button's REAL world position: the board's face CFrame + the button's centre (AbsolutePosition + AbsoluteSize/2 relative to the SurfaceGui canvas, converted with PixelsPerStud / the part size, including the board's tilt). Put an Attachment there, 0.3 studs in front of the face.
- The floor trail ends at the board's standing spot (the free spot in front of it). From there the guide RISES: a 3D arrow (or beam) floats in front of the button at the button's height, pointing INTO the button along the face's normal, with a small bob and a ring pulse on the button.
- When the player is close (under 12 studs), keep only the arrow on the button (no floor trail under the feet).
- If the board moves/tilts or the button moves in the layout, the attachment updates (recompute when the SurfaceGui layout changes).
- Test: every LUMI step that targets a board button (BODIES UPGRADE, PERKS, TREE node, FORGE ROLL, etc.): screenshots from the spawn and from 8 studs, PC + phone. The arrow tip must touch the right button.
```

## Plaza "what is this??" (owner screenshots, 7 Nov)
- **What it is:** the gold circle with 6 glowing dots on the plaza floor is the **star-chart floor inlay**. It's pure decoration, added 2 Nov because the plaza looked empty ("a star-chart floor inlay"). It's built from the brass ring + ChartStar neon dots.
- **Why it's bad:**
  - it glows like an interactable, so it looks like a tycoon button / summoning circle that does nothing (now that pads are pressable, that's worse);
  - it breaks the decided "World glow fix" (#292: lasting glow only on the Core, your pad rim and things ready to press), which was PARTLY built: lamps + floor chart still glow;
  - the lamp-post glow balls also sit in front of the PLAYERS NEAR YOU board's top corners.

```text
PLAZA CLEAN-UP (add to the current job; the owner asked "what is this??" about the glowing gold circle on the plaza floor):
1) The star-chart floor inlay (ChartStar dots + its brass ring) looks like a button that does nothing. Remove it. (Glow is only for things you can press: decided in VFX "World glow fix" #292.)
2) Lamps: no Neon on the lamp heads (SmoothPlastic, warm cream, no always-on glow); keep a soft PointLight only if the area needs it. Move any lamp post whose head sits in front of a board face (PLAYERS NEAR YOU's top corners, TOP SUPERNOVAS, FREE REWARDS) so FACECLEAR is clean from the plaza spawn AND from the bridge.
3) Screenshots: the owner's 3 views (plaza spawn, by FREE REWARDS, by STAR SURGE), before/after.
```

## HUD ART DONE (7 Nov, ChatGPT U4 + U5 → Claude cut → P&L Studios XP Images)
Files: `Celestial Incremental\Assets\ui\hud\hud_*.png` (transparent, cut from magenta with an edge flood fill so the purple gift box survived).
Uploaded as **Image** assets to P&L Studios XP (947215423). Moderation: the panel is Approved, the rest were "Reviewing" at upload.
A stray copy, decal `hud_lumi_panel` 83713788078636, went to Myanmar Builders Club by mistake (the page's creator switcher). It's unused; the owner can archive it.

| piece | image id | size (px) | use |
|---|---|---|---|
| hud_lumi_panel | 126958034325257 | 1383x383 → Roblox stores ≤1024: **1024x284** | LUMI panel. 9-slice SliceCenter Rect(311,89,962,200) (in the 1024 image). The portrait ring is the left ~27%: keep it unstretched (or use the panel at a fixed aspect 3.6:1 and put text in x 0.30-0.95) |
| hud_bar_track | 136600884639828 | 584x120 | progress track, Rect(60,30,524,90) |
| hud_bar_fill | 111345712527230 | 465x92 | progress fill, Rect(46,20,419,72), inside the track with ~5% padding |
| hud_btn_close | 80656129796820 | 183x185 | LUMI hide (round, fixed aspect) |
| hud_btn_skip | 132028182309118 | 183x185 | LUMI skip (round, fixed aspect) |
| hud_tag_step | 72150251114770 | 437x164 | "STEP 12/20" pill, Rect(82,40,355,124), dark text |
| hud_slot_reward | 106310280299667 | 309x294 | the reward slot (fixed aspect) |
| hud_chip_gift | 106148395751692 | 311x194 | NEXT GIFT chip |
| hud_chip_invite | 111001668126320 | 307x194 | INVITE / friends chip |
| hud_chip_group | 116787686626945 | 302x194 | GROUP +10% chip |
| hud_chip_premium | 83690963323861 | 303x194 | PREMIUM +10% chip |
| hud_chip_boosts | 92894565203951 | 310x194 | BOOSTS chip |
| hud_btn_green | 107063255385368 | 277x139 | green button (INVITE / CLAIM), Rect(70,40,207,99) |
| hud_btn_blue | 92410784484864 | 278x139 | blue button, Rect(70,40,208,99) |
| hud_btn_red | 78194072121960 | 278x139 | red button, Rect(70,40,208,99) |
| hud_tag_gold | 135937216600796 | 279x141 | gold tag, Rect(70,40,209,101) |
| hud_pill_violet | 91919107705618 | 354x140 | spare chip pill, Rect(70,40,284,100) |

Chips: use them at a FIXED aspect (UIAspectRatioConstraint ≈1.58). The diamond icon is baked in. Put the text in the pill's dark inside: x 0.56-0.93, y 0.34-0.66 (bold italic white, black stroke, TextScaled + UITextSizeConstraint min 14). On phone, the chip can show just the diamond + a short value.

```text
HUD ART IS READY (owner's new art; replaces the placeholder left chips + LUMI panel). Use the ids + SliceCenters in the table "HUD ART DONE" at the end of Celestial Incremental\2026-11-07 Galaxy Incremental - Tycoon pad fix + HUD art (side chips, LUMI panel).md.
- Left column: GIFT / INVITE / GROUP / PREMIUM / BOOSTS use the chip images (fixed aspect, text inside the pill area, no extra frames, UIStroke or UICorner on top). The INVITE action button = hud_btn_green with "INVITE".
- LUMI panel = hud_lumi_panel (LUMI's portrait inside the ring), the task text in the panel, hud_bar_track + hud_bar_fill for progress, hud_tag_step for "STEP x/20", hud_btn_close (hide) + hud_btn_skip (skip) as small round buttons in the panel's top-right corner, hud_slot_reward for the +1 / +BONUS reward.
- Keep the phone rules (CoreUISafeInsets, no overlaps, UIAudit clean on 5 sizes). Screenshots PC + phone next to the hotbar: it must look like one set.
```
