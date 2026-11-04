# Prompt: our own wide-body carbon kit for the 812 (use after the 812 is imported)

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. **Only start once the owner has imported the 812 model** (it goes through the normal new-model routine in `Better car models and clean interiors.md`, Part 3)._

## What the owner wants (2026-11-04)
A **body kit** for the 812 (in the game a fictional name, e.g. "Rosso Rampante 812"), **inspired by** the photos of a famous tuner's carbon kit for the 812. **We build our own parts in Blender**; we don't use any ripped or downloaded kit model (the owner first asked about a GTA mod; that model is ripped, so it's not used). No tuner name, no logos, no "STALLONE" / brand text anywhere.

**References** (style only), in `Games/CityLegends/imports/refs/bodykit_812/`: `front_3q_left.webp`, `front_3q_right.webp`, `side.webp`, `rear_3q_left.webp`, `rear_3q_right.webp`.

## The kit, part by part (from the photos)
Mixed materials, as the owner asked: **some parts in the car's body paint, some in forged / dark carbon**:
1. **Bonnet:** a new bonnet with a **wide carbon centre stripe / panel** running from the nose to the windscreen, and two big **vents / louvres** either side (carbon). The outer bonnet stays **body colour**.
2. **Front bumper:** a sharper, more aggressive bumper in **body colour**, with **bigger openings** and black mesh, a **carbon front splitter** sticking out, **carbon canards / side blades** on the corners, and a carbon centre fin.
3. **Headlight surrounds:** darker / carbon trim round the lights (keep the model's own lights working).
4. **Front wing vents:** the fender behind the front wheel gets **3–4 carbon louvres / gills** (horizontal slats).
5. **Side skirts:** deep **carbon side skirts** running between the wheels, with a sculpted carbon panel along the lower door (a big carbon blade that sweeps up towards the rear wheel), and a thin lip at the bottom.
6. **Mirrors:** carbon mirror caps.
7. **Rear:** a **carbon panel** across the rear between the round tail lights (keep the 4 round tail lights, which glow red), carbon trim round the lights, and small fins.
8. **Rear diffuser:** a big **carbon diffuser** with vertical fins, a centre brake light, **2 × 2 exhaust tips** (quad exhausts, two on each side), and **body-colour (or red) accent fins** in the lower part, like the photos.
9. **Rear wing:** a **big swan-neck GT wing** in carbon on two tall stands from the boot lid, with **end plates** (a small green-white-red stripe is fine; no text).
10. **Wheels (optional with the kit):** gloss black multi-spoke wheels with a **thin red rim stripe** and **yellow calipers**; a centre cap with no logo.
11. **Ride:** slightly lower and wider stance (wider rear arches if needed so the wheels fill them).

## How to build it
1. **In Blender**, on the imported 812's body (same scale and position):
   - model each part as its own mesh, fitted to the 812's surfaces (no gaps, no floating, no clipping through the body); bevel the edges so they catch light;
   - parts that replace stock parts (bonnet, front bumper, rear bumper / diffuser) **replace** the 812's own pieces in the kit version, so they don't overlap;
   - keep within Roblox limits (each mesh under ~10k triangles; the whole kit under ~40k);
   - UVs for a tiling **forged-carbon** texture (dark grey-black with flecks, glossy clear coat) and for the body paint parts.
2. **Materials:**
   - **body-paint parts** (bumper skins, bonnet sides, accent fins) use the **car's own body paint material** and take the player's **Customs paint colour** (name them as paint parts so `Customs` finds them);
   - **carbon parts** use a `SurfaceAppearance` carbon (colour, normal, roughness; glossy);
   - exhaust tips: dark metal / burnt titanium.
3. **Render** the kit in Blender from the same 5 angles as the reference photos (front 3/4 left and right, side, rear 3/4 left and right), in red, next to the photos. Show the owner before importing.
4. **Import** into Studio (pack it as its own FBX, unique texture names) and add it to the car.

## In the game
- The kit is a **Legends Customs** option for the 812: **"Body kit: Stock / Carbon Wide-body"** (fictional kit name, e.g. "Corsa Carbon"), shown under ★ Bodykits in the dealer, with a price (suggest about 10–15% of the car's price; write it in `Config`).
- Fitting the kit **swaps** the stock bonnet / bumpers for the kit ones and adds the rest; removing it puts the stock parts back. **Saved per car**, seen by everyone (like Customs paint).
- It works with every Customs paint colour and finish; the carbon parts stay carbon.
- Physics: optionally a tiny bit more downforce with the wing (Config), only if the physics system supports it; no big stat changes.
- Tail lights, headlights, exhaust flames (from the new tips) and the cluster still work with the kit on.

## Check before you say done
- The 5 renders next to the 5 reference photos.
- In Play: buy and fit the kit at Customs, drive it (day / night), remove it, rejoin (saved), change paint (body parts change, carbon stays), another player sees it.
- No gaps, clipping or flicker on the car from any angle; FPS not worse.
- No console errors; commit, push, save the place; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- screenshots next to the photos;
- the kit's name and price;
- how to fit it.
