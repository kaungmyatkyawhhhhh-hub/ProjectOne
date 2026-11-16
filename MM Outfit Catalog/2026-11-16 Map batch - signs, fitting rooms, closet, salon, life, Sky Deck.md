---
tags: [mm-outfit-catalog, build-log, map]
created: 2026-11-16
---
# Map batch (owner: "then after, lets do 1-7 map" + "this game map is big. ours is so small")

- **Not saved or published by Claude.**
- **Backups:**
  - `ServerStorage.MapBackups.pre_MediaSalon_16Nov` (the 13 block-sofa and table parts).
  - Everything else is new models and scripts.
- **Game items:** [[2026-11-16 Game batch - outfits, runway, first minute, guest looks, styles, search]].

## 1. Signs
- A hanging sign in the boutique → penthouse doorway reads **"‹ PHOTO BOOTH · GUEST LOOKS ›"** (reversed on the back face).
- Pink floor chevrons just through the door point both ways.

![[Screenshots/2026-11-16 entry sign photo booth guest looks.jpg]]

## 2. Working fitting rooms (`FittingRoomServer` + `FittingRoomClient`)
- "Use fitting room": you step inside, the curtain closes for everyone, and your camera becomes a **mirror**.
- **How the mirror works:** the camera sits behind the mirror, which turns see-through only for you. Your avatar is forced visible (the camera module was fading it), and a warm light fills the booth.
- **Bar:** Styles · Search · Random · My avatar · **Leave**. Walking out also frees the booth.

![[Screenshots/2026-11-16 fitting room mirror.jpg]]

## 3. Lighting technology (owner step)
Scripts can't change `Lighting.Technology`. In Studio: Explorer → Lighting → Properties → Technology → **ShadowMap** (or Future for nicer neon), then Play and check brightness at max graphics.

## 4. My closet (`ClosetClient`)
- The Private Suite is now **MY CLOSET**: a wall with 6 pads.
- Each player sees **their own wishlisted outfits** there (local mannequins, View outfit prompts).
- **Empty closet:** the wall says "tap Wishlist on any outfit and it hangs here".
- The hall signs were renamed.

![[Screenshots/2026-11-16 my closet wishlist mannequins.jpg]]

## 5. Block furniture
- **Lower media salon:** the block sofas and table are replaced with copies of the penthouse mesh **Gallery sofa**, **Library sofa** and **Gallery table**. The invisible Seats are kept, so you can still sit.
- **Not done:** the **games room** next to it still has block stools and a table.

![[Screenshots/2026-11-16 media salon mesh sofas.jpg]]

## 6. More life
- **Barista** behind the café counter (Preppy look, idles). "Order a hot cocoa" gives you a mug to hold for 90 s.
- **Thunder:** the storm flashes every 35–80 s (a double brightening). Not during the photo booth or the viewer.
- **Sounds (ours, not placeholders), waiting for the owner to upload them and add the IDs to `Sounds.Defs`:**
  - `Audio/thunder.wav` (plays as "thunder")
  - `Audio/camera_shutter.wav` (plays as "camera_shutter")
- **Car lights skipped:** the city outside is window art over a bare baseplate 190 studs down, so moving lights wouldn't match.

![[Screenshots/2026-11-16 barista and hot cocoa.jpg]]

## 7. Quality check (quick pass, not the full sim)
**Tells left:**
- Games room block stools.
- The Guest looks booth on the deck is empty until someone publishes.
- The boutique floor is busy with 15 mannequins: store-like, but check it on phones.
- Lighting brightness at max graphics still needs the owner's eyes.

## Bigger map: the **Sky Deck** (rooftop, `SkyDeckServer`)
- **Size:** a 120 × 120 stud open-air deck on the roof, at night in the rain. The boutique floor is about 52 × 42, so this is much bigger.
- **What's on it:**
  - Glass railings and string lights.
  - A big **MM · OUTFIT CATALOG · SKY DECK** sign.
  - A blossom-tree fountain with 6 benches.
  - **7 style booths in a ring**, one per Style. Each shows that style's lead look on a mannequin (the Guest looks booth shows the newest guest look). Tap a booth to open that style's page.
- **Getting there:** the elevator pad "Rooftop Sky Deck" in the boutique (left of the entry door) and "Back to the boutique" on the deck.
- **Layout fix:** the booths sit in two arcs, leaving the arrival view to the fountain and sign open (a south booth blocked it at first).

![[Screenshots/2026-11-16 sky deck from the elevator.jpg]]
![[Screenshots/2026-11-16 sky deck fountain.jpg]]
![[Screenshots/2026-11-16 sky deck booth opens style page.jpg]]

## Tested (Studio Play, PC)
- Sign readable; fitting room enter, mirror and leave (curtain opens again).
- Closet shows wishlisted looks.
- Salon renders; barista + cocoa.
- Elevator up and down; booth → style page.
- 0 console errors.
- **Not tested:** phone layout of the new pieces (fitting room bar, publish card); real multiplayer (hearts from other players, curtain seen by others).

## Phone check (Galaxy A06, 705x338): "cant really see anything cuz its squished"

| Problem on phone | Fix |
|---|---|
| Styles / Search cards cut off (count pill, Try / Buy hidden) | Those pages drop the empty footer strip; on short screens a card fills the panel height (search cards clear the 16 px edge fade) |
| Style names cut to "Y2K &..." | Names wrap to 2 lines |
| First-visit hint covered Featured / Random | On phones it sits top-left |
| Viewer "Drag to rotate" hint under Try it on | Raised above the button row on phones |
| Viewer title "Y2k Pop" | Words with digits keep their case ("Y2K Pop") |
| Cheer button in the middle of the screen | On phones: bottom-right, above the jump button |
| Fitting room bar too wide; mirror cut the shins | Slimmer bar on phones; mirror aims lower and wider |

![[Screenshots/2026-11-16 phone BEFORE styles squished.jpg]]
![[Screenshots/2026-11-16 phone AFTER styles.jpg]]
![[Screenshots/2026-11-16 phone BEFORE search squished.jpg]]
![[Screenshots/2026-11-16 phone AFTER search.jpg]]
![[Screenshots/2026-11-16 phone AFTER viewer Y2K title and hint.jpg]]
![[Screenshots/2026-11-16 phone AFTER fitting room mirror.jpg]]

## Sky Deck v2: top-3 podiums, spiral stairs, runway out, wall out
Owner asked for four changes:
- "in every theme, dont make it like a tent, make it like top 3 of that theme's outfits"
- "make a stairway to rooftop, not elevator"
- "remove the runway"
- "remove this wall"

**Backup:** `ServerStorage.MapBackups.pre_StairsPodiumsRunway_16Nov`. It holds:
- the old booths, elevator, deck and ceiling (before the cut), benches, velvet lounge and pendant
- the runway pieces, the west entry wall and panel and its baseboard
- the roof bits that stuck up through the deck
- the old SkyDeckServer

The runway show scripts are in `ScriptBackups.retired_RunwayShow_16Nov` (disabled).

- **Podiums (7 styles):**
  - **Layout:** the awning and posts are gone. Each style has a 3-step podium with brass numbers: **2 · 1 · 3**, with 2nd on the left as seen from the front. The taller sign behind reads the style name, its line and "TOP 3 · MOST WORN"; Guest looks reads "THE 3 NEWEST LOOKS".
  - **Ranking:** `SkyDeckServer` ranks by the worn count. `OutfitShowcaseServer` shares it as `ServerStorage.MMWornCount`. Ties keep the Config order, and it re-ranks every 5 min.
  - **Prompts:** each mannequin has **View outfit (E)**. The 1st-place step has **Browse <style> (F)**.
  - **Styles widened so every podium fills:**
    - Y2K & Baddie + Soft Pink
    - Preppy & Classic + Varsity
    - Grunge + Denim, Emo

    Edit `Config.Styles` freely.
  - The side mannequins turn 10° inward and the steps are spread out, so arms don't overlap.
- **Spiral stairs:**
  - **Where:** the boutique's west corner, where the velvet lounge and the elevator pad were. The stairwell is cut through the ceiling and the deck (both re-split into 4 pieces around a 10×10 hole).
  - **Build:** 19 wooden steps with brass nosing, a brass column and finial, and a brass handrail. A landing at deck level sits over the first quarter turn.
  - **Deck:** glass guard rails around the open part. One bench moved 3.5 studs so it doesn't block the landing exit.
  - **Signs:** "STAIRS UP TO THE SKY DECK" in the boutique, "DOWN TO THE BOUTIQUE" on the deck.
  - **Elevator removed.**
- **Fall rescue:** anyone below y 150 (off the tower) is put back at the boutique spawn within 1 s. This came up when a test walk dropped to the street.
- **Runway removed:** the floor strip and edge lights, the 3 pink arches, the start ring and the runway show (Cheer, hearts). The mannequin pads stay.
- **Wall removed:** the west boutique → penthouse entry wall, its walnut panel and its baseboard. The boutique now opens onto the penthouse and the stairs.
  - The **Most Purchases** board now stands on brass legs and shows the same rows on its back (`ShowroomBoards` copies them to `BackGui`).
  - The matching east wall stays.
- **Deck clean-up:** 16 old penthouse roof pieces (parapets, roof ends, a mechanical screen and its louvers) stuck 1–2 studs up through the deck. They're moved to the backup.
- **Tested (Studio Play, PC + Galaxy A06):**
  - Walked up all 19 steps onto the deck and back down to the boutique floor.
  - The fall rescue works.
  - All 6 style podiums are dressed. Guest looks is empty in Studio until someone publishes a look.
  - E on a podium mannequin opens its outfit (Soft Pink).
  - The board's back mirrors its front.
  - 0 console errors.
- **Not checked:** real phone thumb-walking up the spiral (only scripted walking), and how the podiums look in daylight lighting.

![[Screenshots/2026-11-16 sky deck top 3 podium.jpg]]
![[Screenshots/2026-11-16 spiral stairs from the boutique.jpg]]
![[Screenshots/2026-11-16 spiral stairs top on the deck.jpg]]
![[Screenshots/2026-11-16 west entry wall removed.jpg]]
![[Screenshots/2026-11-16 phone podium.jpg]]
