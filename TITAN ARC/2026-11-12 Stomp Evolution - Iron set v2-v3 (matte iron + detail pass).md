# Stomp Evolution - Iron set v2-v3 (matte iron + detail pass)

Owner 15:04: "ok good but u still did the same mistakes from when u made the first stage". 15:08: "the details too.... the korblox even have way more detail".

## Repeated mistakes in Iron v1 (all were already in my Stone lessons)
- Plastic: a bright bevel on every edge, light smooth steel, a shiny sky reflection.
- Weird boots: the sky reflection made every upward face pale, so the boots looked like puffy shiny slippers.
- Too little detail: smooth plates and one gem. Korblox has a sculpted chest mask with crystal eyes, a crystal teeth row, crystal clusters, gems and spikes on forearms, knees and boots, a 2-tier skirt and pale trims everywhere.

## v2 paint (iron_v2_paint.py)
- Matte forged iron: hammered mottling, a little rust, grime, fine wear lines, subtle scratches.
- Dark plate outlines with only a faint lip. No environment reflection.
- Dark values: plate (66,74,90), trim (40,45,56).
- Glyph band on big flat plates.

## v3 geometry (iron_v3.py): detail pass, then everything scaled up about 1.8x so it reads
- spike() (faceted pyramid, any material) and trim() (thin polished band) helpers.
- **Chest:** a row of 6 glowing crystal fangs under the chest plate, a collar rivet row, polished collar and lower trims.
- **Shoulders:** blade fin plus a cyan gem in a polished socket on the front of each pauldron.
- **Forearms:** a big cyan gem in a polished socket, 2 swept fins down the back, 2 trims, rivets.
- **Upper arm:** trim plus a rivet row.
- **Waist:** belt edge trims, a 2nd tier of side tassets, rivets.
- **Knees:** a cyan gem plus a spike.
- **Shins:** 2 swept side fins, trims under the knee and at the ankle.
- **Boots:** heel spur, polished toe cap, rivets.
- Paint (iron_v3_paint.py): "metal" = polished steel trims (92,112,140 to 214,230,246), tube-shaded = the contrast colour.
- About 104k triangles (reduce before launch).

## Assets (group 33151111), live as Armour.Iron
| Asset | ID |
|---|---|
| IronSet_v3 model | 91555232466764 |
| Torso | 127886890302429 |
| LeftArm | 93277664198090 |
| RightArm | 104099016499802 |
| LeftLeg | 70414883522183 |
| RightLeg | 70414499889879 |
Attachment shifts vs Iron v1: LowerTorso (0, -.0796, 0) json; UpperLegs z -.064; LowerLegs x +-.1188; Feet (+-.052, 0, .0742); LowerArms (+-.0612, 0, .1362), applied as (dC.x, -dC.y, dC.z).
Place saved as version 27.

## Next
- Stone needs the same detail pass (now plain next to Iron v3).
- New: [[Armour set QA checklist (run before showing ANY set)]]. Run it before every set.
