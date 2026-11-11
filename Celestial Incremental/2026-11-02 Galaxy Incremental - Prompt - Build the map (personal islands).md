---
date: 2026-11-02
tags: [galaxy, prompt, map]
status: todo (Claude Code, Galaxy session)
---
# Prompt for Claude Code: build the Galaxy Incremental map (concept v3)

Owner (2 Nov): "yes do that in the real build". Spec: [[2026-11-02 Galaxy Incremental - Map design and quality]] (concept v3 + its fixes), render `Map\galaxy_map_concept_v3.png`, Blender script `Map\galaxy_map_concept_v3.py` (positions, sizes, colours).

```text
GALAXY INCREMENTAL: build the map in the Galaxy place (P&L Studios XP). Never touch GYM ARC.
Read: Celestial Incremental\2026-11-02 Galaxy Incremental - Map design and quality.md (DECIDED sections + concept v3), look at Map\galaxy_map_concept_v3.png, use Map\galaxy_map_concept_v3.py for layout numbers (Blender units ~= studs x 2.5; keep the proportions).

1) LAYOUT: a small CENTRE island (Supernova Core on a brass altar with 3 gyroscope rings, Upgrade + Tree boards, Star Forge platform with a padlock "SUPERNOVA 3", Black Hole gate = brass ring + violet void, locked) and 8 PERSONAL islands in a ring around it, each linked by a short arched light bridge (~10-15 studs). The locked next-sector island (icy) across the void with its own bridge that lights up at the Ignition gate.
2) PERSONAL ISLAND = the player's place: claimed on join, freed on leave (the save keeps progress, not the island). Spawn ON your island facing the Core. Every window opens from the hotbar anywhere (walking to the centre is optional).
3) ISLAND GROWS (tycoon feeling), pieces appear with a pop + sparkle at milestones: bare rock -> stone disc -> brass rim -> lamp pillars -> crystal garden + green patch -> banner in the player's colour + outer ring -> telescope + brass dais (+ new pieces per sector later). Map the milestones to the design's progress (bodies owned / Supernovas); put them in a Config table.
4) STAR SYSTEM above each island grows with what the player owns (rock -> star + planets on orbit rings), stardust motes rising. Others' systems simplified past ~60 studs.
5) NAME PLATE floating over each island: player name + rank/realm, in the player's colour (the fix from concept v3). The bare-rock island also gets its bridge.
6) SHARED MOMENT: when anyone goes Supernova, the Core bursts and a shockwave ring sweeps across all islands.
7) LOOK RULES: low-poly faceted, glossy, bold colour blocks (same as the icons in Icons\rendered\); warm stone + brass ground vs violet galaxy sky (skybox + a few nebula shapes); gold/brass = interactive; glow only on interactive/ready things; textures static, VFX animated (Core pulse, motes, comets streaking past and clickable, shockwave, sparkles on ready islands). No glass, no see-through parts, no emojis.
8) BUILD: one reusable kit (~20 pieces: island disc, rock underside, rim, pillar+lamp, ring, crystal cluster, banner, telescope, board frame, bridge segment, dais) as MeshParts; make meshes in Blender if needed and put the .fbx files in Downloads for me to import into P&L Studios XP (assets must belong to the group). StreamingEnabled, few lights (Core + 1 per board), phone check at 667x375, FPS with 8 players.
9) Screenshots: wide view like the concept, one island at every tier, phone view. Progress note in the vault each day.
```
