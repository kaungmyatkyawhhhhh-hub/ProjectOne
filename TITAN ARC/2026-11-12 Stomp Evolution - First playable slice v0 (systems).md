# Stomp Evolution: first playable slice v0 (12 Nov 2026, evening)

Design doc §13 + impatient-kid sim version H numbers. Place saved (v34). Play-tested in Studio: stomp, pads, evolve to Stone, Star (x8.6 body).

## What is built
- `ReplicatedStorage.StompEvolution.Config`: props (need / mass / coins / respawn), 8 forms with HEIGHT gates 0 / 1.9 / 2.4 / 3.0 / 4.5 / 8 / 13 / 21 m, upgrades (Power 8x2.1, Shock 20x2.6 max 4, Speed 12x1.7 max 6), Ground Pound (first at stomp 6, every 15th, x6, +3 props), golden 1/200 x25, first golden for new players at 22-32 s, welcome 10 coins.
  - HEIGHT = 1.7 (1 + mass/40)^0.24; body scale = (HEIGHT/1.7)^0.85 (Star ~8.5x).
- `ServerScriptService.StompServer`: DataStore StompEvolution_v1 (autosave 60 s), server-validated stomps (cooldown, reach, height gate), shockwave extra props, prop hide + respawn (6-12 s), ArmourKit form swap + `Model:ScaleTo`, WalkSpeed/JumpHeight scale, step-on upgrade pads, crown (tallest, 20 s gap) + height tags, leaderstats. Studio-only test hook `ServerStorage.SE_Debug:Invoke(player, mass, coins)`.
- `StarterPlayerScripts.StompClient`: click / E / R2 / mobile STOMP button (hold = auto), nearest-in-front target, leg slam (Motor6D.Transform in PreSimulation), dust ring, debris chunks, camera shake, +MASS / +coins popups, HUD (HEIGHT, NEXT bar naming the next form, coins), pad signs per player, lock badges "BE 6 m", evolve flash + banner, camera zoom grows with the body.
- `workspace.ToyTown`: 1,300-stud street; 289 props (flower beds, mailboxes, bins, bikes, cars, buses, houses, shop rows, tower blocks); 3 pad trios (x 40 / 330 / 800).

## Lessons
- StreamingEnabled: a prop far away has no parts on the client yet, so `GetBoundingBox` is empty and the target picks a ghost at 0,0,0. Store Center/Size as attributes on each prop model in Edit; ModelStreamingMode Atomic.
- `_G` is not shared between a game Script and the MCP command VM: use a BindableFunction for test hooks.

## Not done yet (next)
1. Prop ART: props are part-built toy blockouts. Need the high-quality pass (Blender kit like the armour sets).
2. SOUND: no sounds yet (stomp thud, crumble, coin, evolve). Make code-synthesized ones (owner rule: not Fish Audio).
3. Re-run the impatient-kid sim on this LIVE config; then a phone test.
4. DataStore: turn on Studio API access (Game Settings > Security) to test saving.
5. Later slice items: Rampage (Rogue Titan), district 2 + Scrap Colossus boss, Smash Index, transform cutscene + new move per form.
6. Star cape texture 86535098135155 failed once in Play ("no asset content representation"); re-check.
