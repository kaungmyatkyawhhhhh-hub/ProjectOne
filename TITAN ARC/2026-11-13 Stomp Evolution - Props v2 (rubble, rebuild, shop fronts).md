# Stomp Evolution - Props v2: rubble that stays, visible rebuild, shop fronts — 13 Nov 2026, ~00:00-00:30 (autopilot)

Owner: "ok do those stuff on autopilot" (the 3 open items from Props v1).

## 1. Crumble by material
- 5 rubble piles from Blender (`Art/Props/v2/rubble.py`, same palette texture): Garden (soil, petals, planks, leaves), Plastic (shards, lid, bent post, flag), Metal (crumpled body, tyres, glass, rods), Brick (bricks, roof tiles, window frame, beam, door), Concrete (slabs, rebar, glass).
- Vehicle wrecks come in 6 colours (red, sky, yellow, orange, blue, green) so a yellow taxi leaves a yellow wreck.
- Assets: SE_props_v2 76209997370421 (shop rows v2 + 5 piles), SE_rubble_metals 101365876908623. In Studio: ServerStorage.StompEvolution.Rubble.
- Config.Crumble[kind] = {rubble, rubbleV (per variant), cols[variant]}.
- Server breakProp: the prop hides and a pile (scaled to its footprint, max 45% of its height, random yaw) stays until respawn.
- Respawn = visible rebuild: the pile goes and the prop rises out of the ground (0.55 s Back ease).
- Client debris: chunk colours now come from Crumble cols by kind + variant (the one-mesh props made every chunk grey), and more chunks for bigger props.
- "Cracked" middle state: skipped on purpose. Every prop breaks in one stomp, so a cracked state would never be seen. The debris + pile + rebuild carry it.

## 2. Shop rows v2
- Upper windows on every shop, pilasters, a band under the windows, a stone skirting, sign brackets, windows on the end walls. ~9k tris.

## 3. Overlaps near spawn
- Small props (flower, mailbox, bin, bike) pushed apart so footprints never touch (1 stud gap). Checked top-down at spawn.

## Tested
- Play: stomping a car leaves a wreck in its own colour, the taxi a yellow wreck; props rebuild at home position; no errors. Saved.
