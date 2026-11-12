# Armour set QA checklist - run before showing ANY set to the owner

Why this exists: on 12 Nov the owner said Iron v1 "still did the same mistakes from when u made the first stage". The lessons were written down after Stone, but nothing forced me to check them on the next set. This list is that check. Go through every line next to Korblox General in Studio (not only in the Blender render), and fix before showing.

## Shape
- [ ] Symmetric: left and right shoulders, arms and legs match (no one-sided pauldron, blade or cape-only side).
- [ ] Bundle proportions: lower torso narrower than the chest (no wide or feminine hips); upper leg 0.75-0.95; forearm 0.9-1.1.
- [ ] Not blocky: rounded or bevelled forms, tapered limbs.
- [ ] Not stiff: angled rims (elbow guard up at the back, knee guard peaked at the front, plates sweep down outside). Spikes sweep back and out. No straight drums with flat rims.
- [ ] No dark suit showing at hip, elbow or knee: plates overlap the joints.
- [ ] Boots like Korblox: greave tapers into a tall ankle cup, overlapping plates, rounded toe, thin sole. No bucket cuff, no glowing sole slab, no pale or shiny "slipper" look.
- [ ] Hands are the ROBLOX Boy meshes with a SurfaceAppearance glove (no TextureID on them).
- [ ] Nothing floats: every spike, crystal, gem or moss piece is sunk into the surface it grows from (use dome_top() or the real surface height).

## DETAIL (owner 15:08: "korblox even have way more detail")
- [ ] Every body part has at least 2 distinct accent details, big enough to read at normal camera distance (about 1.8x what feels right in Blender):
  - chest: a focal piece (gem or emblem) plus a row of crystal fangs or a similar motif
  - shoulders: spikes or blades plus a gem plus a trim
  - forearms: a gem socket plus fins or spikes plus trims
  - waist: a 2-tier skirt plus belt trims
  - knees: a gem plus a spike
  - shins: side fins plus trims
  - boots: a heel spur plus a toe cap plus rivets
- [ ] A CONTRAST trim colour (like Korblox's pale trims) frames the plates, as polished bands.
- [ ] Accents that must read are bright or glowing (crystal), not dark on dark.

## Material / texture
- [ ] No bright rim on every edge, no smooth fill, no shiny sky reflection: dark plate outline, only a faint lip, grain, mottling, cracks or wear.
- [ ] Values dark enough (match the line-up colour, not lighter).
- [ ] Glyphs and patterns only on flat faces, big enough to survive about 256 px.
- [ ] One map per limb, hidden UV islands shrunk; the mesh and its maps uploaded together (UVs change on every export).
- [ ] All 5 textures show Success in Studio (wait about 60 s after Approved; re-upload a byte-different copy if one fails).

## Test
- [ ] Studio, Edit: next to Korblox, front and 3/4, close-up on the chest, hands and boots.
- [ ] Play: ArmourKit.Apply on the owner's avatar; walk pose frame next to Korblox.
- [ ] Screenshot is OUR model (check which is which before sending).
