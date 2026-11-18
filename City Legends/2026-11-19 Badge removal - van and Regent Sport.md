# Badge removal: Grand Lounge van and Regent Sport (19 Nov 2026)

Rule (owner, permanent): no real car brand badges, logos or name lettering anywhere. Follow-up from [[2026-11-19 Jobs SWFL - jobs menu, workplaces, vehicles, AFK posts]].

## What was found
Both cars are built in Roblox (not converted), so `BrandMarks` had no entry for them. Their badges are not separate parts: they are cut into big chrome / trim meshes, which is why the "badge / logo" name search in CarSkin never removed them.

**Apex Grand Lounge van (`toyoka_alfard`, the YBS van)**
- Tailgate: maker's oval badge on the chrome bar (inside the tailgate trim mesh `Misc.TK.MeshPart`).
- Tailgate: "ALPHARD Executive Lounge" lettering (its own small part).
- Grille: the model's shield emblem (inside the chrome grille bars mesh).
- Wheels: maker's logo on all 4 centre caps.
- Steering wheel: replaced in game by our generated "ToyotaModern" wheel (no logo). Interior: nothing found.

**Apex Regent Sport (`toyoka_crown`, NPC police car `Config.Police.CarId`, traffic kind E)**
- Boot: maker's badge, "CROWN" on the left, "ATHLETE G" on the right, a hybrid plate under the right lamp (all inside the chrome trim mesh).
- Grille: crown emblem.
- Front fenders: "HYBRID" plates, both sides.
- Wheels: crown emblem on all 4 centre caps.
- Steering wheel: replaced in game (ToyotaModern). Interior: nothing found.

## What was fixed (Studio, main City Legends place, saved as version 1495)
- The van's tailgate lettering part was deleted from `CarModels` (backup: `ServerStorage.BadgeRemovalBackup`).
- 17 `MarkPatch` parts were added in `ReplicatedStorage.CarModels`: 6 on the van and 11 on the Regent Sport. Each is a plain patch in the colour around the mark, and each sits in the group of the mesh it covers, so it moves with the tailgate or wheel:
  - The van's rear badge is covered by a round chrome disc on the chrome bar.
  - The van's grille emblem gets a dark block.
  - The Regent's boot marks and HYBRID plates get white paint patches in its `Body.Paint` group.
  - The Regent's grille emblem gets a grey block.
  - All 8 wheel caps get rim-coloured discs.
- No fictional emblem was used: there is none for this make, and the owner's 22 Oct rule says plain covers only.

## Repo (so it sticks)
- `tools/brand_marks/RobloxBuiltPatches.luau` stores every patch relative to the model's pivot. `P.run()` lays them all again on a fresh copy of the models.
- `BrandMarks.toyoka_alfard` hides the lettering part by name and size if an old copy of the model comes back. The same entry is in `marks.json`.

## Shots (Studio Edit, raw CarModels copies)
![[2026-11-19 Badge removal - Grand Lounge van tailgate - before.jpg]]
![[2026-11-19 Badge removal - Grand Lounge van tailgate - after.jpg]]
![[2026-11-19 Badge removal - Grand Lounge van grille - before.jpg]]
![[2026-11-19 Badge removal - Grand Lounge van grille - after.jpg]]
![[2026-11-19 Badge removal - Grand Lounge van wheel - before.jpg]]
![[2026-11-19 Badge removal - Grand Lounge van wheel - after.jpg]]
![[2026-11-19 Badge removal - Regent Sport tailgate - before.jpg]]
![[2026-11-19 Badge removal - Regent Sport tailgate - after.jpg]]
![[2026-11-19 Badge removal - Regent Sport grille - before.jpg]]
![[2026-11-19 Badge removal - Regent Sport grille - after.jpg]]
![[2026-11-19 Badge removal - Regent Sport wheel and fender - before.jpg]]
![[2026-11-19 Badge removal - Regent Sport wheel and fender - after.jpg]]

(The plate text is missing in the after shots because the copies had their scripts removed.)

## Other traffic and police models
- `ReplicatedStorage.TrafficModels` in the place today holds the old low-poly CC BY pack (Traffic_A1 ... F6, 15-17 parts each). They have no badge parts or decals.
- The new Yangon traffic set (`TrafficMix`, `tools/yangon/TrafficLOD.luau`) makes its copies from `CarModels`. When it is installed it inherits these patches. Its "tiny" cut drops parts whose longest side is under 2% of the car's length (about 0.38 studs). That drops only the 0.26-0.28 wheel discs, which are too small to read at traffic distance anyway. The body patches are 0.38 or more and stay.
- `Police.lua` (client) builds its NPC cars from `Config.Police.CarId` = `toyoka_crown`, so it is covered now.
- **Still to check by eye, same problem likely:** every other car built in Roblox that has no `BrandMarks` entry and sits in `TrafficMix`: `suzaki_swift`, `toyoka_belta`, `toyoka_camri`, `toyoka_lc200`, `byt_seal`, `kio_ev6`, plus probox / hiace / carry / ybs (our own low-poly models, probably clean). Use the same method on them: tint the parts, shoot, patch.

## Not tested
- Play, i.e. CarSkin's live copy with the patches, the YBS van repainted white and red, and the police NPC. The geometry is the same as in Edit, but the in-game look is unchecked.
- Tyre sidewall text on the van ("Explorer ...", the model's tyre picture). It is not a car maker, so it was left as is.

## How (method, for the next car)
1. Clone the model to an empty spot (y 800) and take front, back and wheel shots with `screen_capture`.
2. Find the part that carries each mark by tinting the candidates in bright colours, one shot per round.
   - Ray-box hits along the pixel ray narrow the list.
   - `screen_capture`'s pixel-to-ray mapping was about 1.7x wider than a 70° FOV.
3. Place each patch: hit point plus normal. Precise collision on the clone gives better hits.
   - **Trap:** setting `PreciseConvexDecomposition` on about 200 meshes froze Studio for about 8 minutes. Do it only on the few parts you need.
4. Check every patch from two angles. Grow it until nothing peeks round the edge.
5. Copy the patches into `CarModels` by their CFrame relative to the pivot, then save.
