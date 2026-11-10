# Prompt: "Rocket" becomes a body kit for the G63 (no separate Rocket car)

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **No errors:** if a part can't be made clean, leave it out and note it. Works like `812 body kit (use after importing the 812).md` (same Customs body-kit system)._

## What the owner wants (2026-11-10)
"Brabus is going to be a body kit for the G63." In the game: the **Rocket W463 800** (`brabos_g63`, our fictional tuner brand "Rocket") stops being its own car and becomes a **body kit (and tune) for the Tri-Star Silber W463 V8** (`bentz_g63`).

## When to do it
- The kit is built on the **G63's model**. The G63 still has its **old model**: if the owner imports a new G63 model first, build the kit on the new one; if not, build it on the current model now and refit it later.
- No ripped or downloaded tuner kit: **we build our own parts in Blender**, inspired by the well-known wide-body G-Class tuner look, with **no tuner name, logos or lettering** anywhere (only our own "ROCKET" word where a tuner badge would sit, if it looks good; no real tuner's font or emblem).

## The kit: "Rocket Widestar"-style (our name: "Rocket 800 Wide-body")
Mixed materials: body colour plus dark / forged carbon, like the real style:
1. **Wide arches:** wider front and rear fender flares (carbon or body colour), so bigger wheels fill them; the stance a little lower and wider.
2. **Bonnet:** a bonnet with a raised **carbon scoop / air intake** on top.
3. **Front:** a new front bumper with bigger intakes and a carbon splitter; the grille in black with small extra LED lights (warm white, not neon) in the grille or bumper.
4. **Roof:** a **carbon roof spoiler** over the windscreen with a row of LED lights (warm white, switchable with the headlights).
5. **Sides:** carbon side-step / skirt trims and the side exits for the exhausts (in front of the rear wheels, like the real style) with dark metal tips.
6. **Rear:** a carbon rear diffuser / bumper trim, a carbon cover for the spare wheel on the back door (no logo).
7. **Wheels:** big 23–24" style multi-spoke wheels in gloss black or dark grey (our own design, no logo), with the tyres to match.
8. **Mirrors and trims:** carbon mirror caps, black window trims.
- Each part fitted to the G63's surfaces (no gaps, floating or clipping), bevelled edges, under Roblox limits (each mesh under ~10k triangles, the whole kit under ~40k), UVs for forged carbon and for paint.
- Body-colour parts take the **Customs paint** (named as paint parts); carbon stays carbon.
- Lights on the kit (grille / roof LEDs, side exhausts) work **in their proper place** and follow the car's lights.
- Render the kit in Blender from front 3/4, side and rear 3/4 before importing.

## In the game
- **Legends Customs / the Workshop body-kit option for the G63:** "Body kit: Stock / **Rocket 800 Wide-body**", with a price (about the real tuner kit cost × the game's part price rules; note it).
- **Rocket 800 tune** (optional, with the kit or separate): a power tune that brings the G63 to the old Rocket car's numbers (about 800 PS, its 0–60 of 3.9 s); counts in PI / class like other parts (check the class rules).
- Fitting the kit swaps the stock bumpers / bonnet / arches for the kit's and adds the rest; removing it puts the stock parts back; saved per car and seen by every player.
- The kit works with every paint colour and finish; tail lights, headlights, the cluster, the hitch (the G63 can tow: the hitch must still fit the new rear) and doors (if the G63 has working doors) still work.

## The old Rocket car (`brabos_g63`)
- Take it **off sale** everywhere (dealer, market, rewards, spin wheel, lists; add it to `Cars.RETIRED`).
- **Players who own it:** give them a **G63 with the Rocket kit and the Rocket 800 tune already fitted** (keep their car level, XP, CP, parts and paint by moving them onto the G63 if they don't own one; if they already own a G63, put the kit + tune on it and give the difference in CP). Nobody loses value. Write a save-move test (like `tools/carlevels_test.luau`).
- **The "Rocket" brand:** keep it as the **kit / tuner name** only. If no car is left under the Rocket make, take it out of the dealer's brand list (keep `Cars.Makes` / `Cars.OldBrands` working so old saves and brand XP don't break), and move any Rocket brand XP to Tri-Star Silber.
- Update the logo sheet's note: the Rocket badge is now the kit's badge.

## Check before you say done
- Renders of the kit (3 angles), and Play screenshots: stock G63 vs Rocket kit, day and night, in 2 paint colours; from the driver's seat (no kit part blocking the view).
- Fit / remove the kit and the tune, rejoin (saved), another player sees it; the PI / class shows right.
- A test save that owned the Rocket car: after joining it owns a G63 with the kit and tune, with its progress.
- No gaps, clipping or flicker; no console errors; FPS fine; Lune tests and `luau-lsp analyze` clean.
- Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- screenshots stock vs kit;
- the kit's and tune's names and prices;
- what happened to Rocket car owners.
