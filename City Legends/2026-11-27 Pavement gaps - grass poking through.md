# Pavement gaps - grass poking through (27 Nov 2026)

Owner: in a picture there was a sloped grey block with a broken edge between pavements, and grass. "idk where it is too. i think its like that everywhere".

## Cause
- The road pavements (RMeshP) are runs of flat slabs at slightly different heights along curves. Between them there are triangular gaps, and road meshes have hairline seams.
- The terrain under them is grass, sometimes just under the surface and sometimes about 9 studs below. It shows through as jagged green wedges in the pavement and thin lines across the road.
- Proof: grass recoloured magenta lit up every wedge and seam.

![[refs_2026-11-27_pavement_gaps/before_grass_wedges.jpg]]
![[refs_2026-11-27_pavement_gaps/cause_terrain_magenta.jpg]]

## Fix (Studio terrain only, whole map)
- **Which pieces:** every road collision box with RoadBox "P" (pavement, 51,693) or "R" (road, 119,187).
- **Which ground:** terrain columns inside the box's real footprint (not its world-aligned box) whose top surface is more than 0.6 studs below the surface.
- **What changes:** Grass, LeafyGrass, Ground and Mud from 14 studs below up to the top become Concrete under pavements and Asphalt under roads. A gap now shows grey, not green.
- **Colour:** Concrete terrain was recoloured to pavement grey (138, 135, 128). This affects any other Concrete terrain too.
- **Left alone:** flush ground (terrain level with the surface, i.e. ground you can see) and Pavement terrain (the Myanmar Plaza paved lot).

![[refs_2026-11-27_pavement_gaps/after.jpg]]

## Lesson (mistake on the first try)
- The first pass replaced terrain inside every box's world-aligned bounding box, with no height test.
- Some R boxes cover open ground with no visible road, so whole fields turned dark asphalt.
- It was undone step by step (ChangeHistoryService:Undo, then the same spots checked), then redone with two tests: only ground hidden under the surface, and only inside the real footprint.
- **Rule:** before any mass terrain edit, test on two spots, one of them open ground next to a road.

![[refs_2026-11-27_pavement_gaps/mistake_first_try_dark_field.jpg]]

## Not done
- A few flush grass spots inside pavements are still left, by design; they're rare.
- The stepped slab heights themselves are still there; they now read as slab joints.
- The concrete street texture: the owner says real concrete has no panels and no mirrored band. The roads helper is redoing it.
