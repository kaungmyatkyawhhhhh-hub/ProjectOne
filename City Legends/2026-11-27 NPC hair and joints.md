# 2026-11-27 NPC hair and joints

Owner (27 Nov, screenshot of a walker in a white shirt and blue checked longyi): "in npcs, their hair is messed up and when they walk, i can see their skin between the joints and same for arm joints too."

## What was wrong
- **Skin in the joints.** Every Blocky piece had clothes only on its 4 sides (and the top of a limb's first piece). The faces a joint opens (the bottom of the upper arm / thigh / chest, the top of the forearm / shin / pelvis, the pelvis between the legs) had no clothes, so they showed the skin colour when an elbow, knee, hip or the waist bent.
- **Elbow and knee hinges sat on the middle of the joint.** Bending opened a wedge on the outside of the bend (back of the elbow, front of the knee) that showed those bare faces. The run bent the knee up to ~2.0 rad and the elbow to ~1.75 rad: far past where a block can fold.
- **Hair.** The placement maths was right (checked against Roblox's own Pal Hair: HairAttachment (0, 0.35, 0.25) on the handle, head HairAttachment (0, 0.6, 0), so Off = (0, 0.25, -0.25), as stored). Two of the kit hairs were the problem: **Sideswept Bangs** (kit name "Shaggy") is a fringe only, so on its own it is a black cap stuck on one side of the head; **Messy Hair** with its texture cleared reads as a cap with two skin holes.

## What changed
- `src/client/YangonStreetLife.lua` `clothe` / `setClothes`: every clothed piece also wears its joint faces (bottom face, and the top face of the lower pieces): a Texture cropped to the front picture's 2-pixel row at that edge, so a long sleeve / longyi / shirt carries on into the joint and a short sleeve's row stays skin. Soles of the feet stay bare (hidden). 53 -> 70 Textures a person (2 shared atlases, 20 people max).
- `src/client/PedMotion.lua`: the elbow hinge sits on the back edge of the forearm, the knee hinge on the front edge of the shin (the side the bend opens), so the pieces stay joined there and only overlap inside the bend. Knees clamped to 1.45 rad, elbows to 1.6 (about what Roblox's own walk / run bend); the phone-at-ear elbow keeps its fold. The procedural walk / run itself is unchanged.
- Studio: `ReplicatedStorage.PedKit.Hair` now holds Pal, Stylish, Brown, Spikes, Trecky, Charmer, Updo. Sideswept Bangs ("Shaggy") and Messy moved to `ServerStorage.PedKitHairUnused` (kept, not deleted).
- Studio scripts synced (Source written), place saved v2384, store back on `CityLegends_v1`.

## Pictures
- Before: ![[2026-11-27 NPC hair and joints - before (skin at the waist).jpg]] ![[2026-11-27 NPC hair and joints - before (Sideswept Bangs on a walker).jpg]] ![[2026-11-27 NPC hair and joints - before (Messy Hair reads as a holed cap).jpg]]
- Kit hairs on one head (Sideswept Bangs in the middle): ![[2026-11-27 NPC hair and joints - kit hairs lineup (front).jpg]] ![[2026-11-27 NPC hair and joints - kit hairs lineup (side, Sideswept Bangs centre).jpg]]
- After: ![[2026-11-27 NPC hair and joints - after (walk, side, mid-stride).jpg]] ![[2026-11-27 NPC hair and joints - after (run, side, elbow folded).jpg]] ![[2026-11-27 NPC hair and joints - after (run, front, knee up).jpg]] ![[2026-11-27 NPC hair and joints - after (runner and walker).jpg]] ![[2026-11-27 NPC hair and joints - after (hair on several NPCs).jpg]] ![[2026-11-27 NPC hair and joints - after (updo and spikes).jpg]]

## Lessons
- A part split into pieces needs clothes on the faces its joints open, not just its outside.
- Hinge a block joint on the edge the bend opens, and keep the bend under ~90 degrees.
- Before adding a catalog hair to the kit, look at it alone on a bare head from the front and side: fringe / bangs accessories are not full hairs, and some hairs only read right with their texture.

## Not done / open
- The short-sleeve edge on the arm's side face looks jagged up close (the clothes template's side picture, not the joints).
- Only one long hair (Updo) for women; more Roblox women's hairs would add variety.
