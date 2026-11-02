---
date: 2026-11-02
tags: [gymarc, progress, moderation, urgent, hotfix]
status: done in Studio, NOT published yet (the owner publishes)
---
Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-11-02 GYM ARC Prompt - URGENT hotfix Sexual Content suspensions]] · Bug: [[2026-11-02 GYM ARC Bug - players suspended for Sexual Content (avatar)]]

# Hotfix: players suspended for "Sexual Content" (clothes always on)

## What made players look naked (2 causes)
1. **The real character on the server was a bare skin body.** `Body.ApplyTo` takes off every avatar's Shirt, Pants and T-shirt (to swap in the Robloxian 2.0 body). The muscles, the tank top and the shorts are drawn only on each player's own screen (MuscleRig, client side). So the character that Roblox's servers know about was a plain skin-coloured body with no clothes at all, for **every** player, whatever avatar they joined with. Roblox's avatar check most likely looked at that. Shot: `01_server_body_BEFORE_bare.jpg`.
2. **Clothes vanished behind Glass.** Any body piece that wears a clothing picture (NPC shirts, trainer outfits, the "Mine" shirt, gym fits) is set to Transparency **0.02**. That way the picture's see-through spots show a solid "Skin" copy just inside it (`BodyStages`, `LimbStages`, `MuscleRig` cloth). Roblox does not draw see-through parts behind a Glass part. So behind the 229 windows that turn to Glass by day (`NightLightService`, attribute `DayMaterial = "Glass"`), the picture layer disappeared and the solid copy underneath was **skin**. That is why everyone looked naked through windows. The player's own thigh shorts are also a see-through layer (vertex alpha, MuscleRig). Test shot with one window switched back to Glass: `03_powerlifting_window_as_GLASS_test.jpg` (the coach's shirt picture and every name tag gone).

## Fixes (Studio)
- **Server clothes:** every player's character now wears a classic **Shirt "GymArcSafeTop"** (white tank top) and **Pants "GymArcSafeShorts"** (black shorts, hips to past mid-thigh, front and back). They're re-checked every second in `BodyService.EnsureSafeClothes`, called from publish. A gym fit's own Shirt is left alone; only the shorts are added. Images are game-made (`GYM ARC/Art/SafeClothes`, uploaded on the owner's account): tank 132306476693023, shorts 130947746187832. Config: `Body.SafeClothes`. The clients ignore these two (`MuscleRig.StyleFrom`), so the muscle look is unchanged. Shot: `02_server_body_AFTER_tank_shorts.jpg`.
- **No Glass anywhere:** the 229 windows' `DayMaterial` is now SmoothPlastic. 216 solid building windows stay solid. The 13 see-through ones (Sauna, Clothing Store display, Powerlifting front) are now light blue `#BFE3F5` at Transparency 0.4. The Runway screen, the VIP plate-tree crystals, the intro set crystal and the ModelMeshes window/truck glass are SmoothPlastic too. Scripts: the shaker bottle (ItemService), a trainer's lens (TrainerService) and the genetics bar grip (GeneticsClient) no longer use Glass. Checked in Play: 0 Glass parts by day and at 22:00. Old backups in ServerStorage were not touched.
- **Solid cloth under every clothing picture:** the copy inside a picture-wearing torso piece is now the top's colour (white tank if none), never skin. Under a trainer's shorts it is the shorts colour (`BodyStages`). If a picture layer is ever dropped again, the chest, back, hips and thighs stay covered.
- **Far / low-detail bodies:** the plain thighs are painted as the shorts (Fabric, no skin map). Before, only the hips (LowerTorso) were, which looked like briefs (`MuscleRig.DressBody`, `SHORTS_PARTS`).
- **No shirtless (`Body.AllowShirtless = false`):**
  - "Mine" is removed from the clothing store's tank list. A saved "Shirtless" wears the white tank top, and the white tank shows as worn.
  - Players always wear the game's top (`TopOverShirt`).
  - A body with no top and no shirt picture gets the white tank top (`StyleFrom`); this covers trainers with no outfit shirt too.
  - The mirror's full-potential body keeps the tank top.
  - The Hall of Fame statues now wear a cloth tank top and shorts on the marble (`BodyStages` clothOnStone, `DressBody`). Shot `11_hall_statue_tank_shorts.jpg`.
  - The code stays; set `Body.AllowShirtless = true` to bring "Mine" back (not advised).

## Tested (Studio Play, temporary data)
- Through the windows: Starter Gym, Members Gym, VIP Gym, Pro Gym door, Powerlifting front, Golden Era, Clothing Store. The player (white tank, black shorts) and Coach Lou (yellow shirt) show fully clothed in every one. Shots 04-10.
- Every NPC (18), the 4 statues, the money trainer and the player: no torso shows skin.
- The server body seen without the client muscles: tank top + shorts (shot 02).
- No errors in the output.
- **Avatars without clothes:** the body swap takes every avatar's clothes off anyway, so every avatar looked the same to the game before; the safety clothes go on whatever the avatar is.
- **Not tested here:**
  - A real night view: a game script holds the client's clock at day. The server's windows at 22:00 are all SmoothPlastic, so there is no Glass at night either.
  - A real phone: Studio can't render as a phone. The phone's low-detail bodies use the same plain-body paint that was checked.

## Not changed (say if wanted)
- **Glute / crotch shapes:** not flattened. They sit under the shorts, which are now solid on every view; flattening needs the muscle mesh data rebuilt.
- **Your own thighs:** the shorts on your OWN body are still a see-through layer (vertex alpha, only on your screen; everyone else sees your solid stage shorts). With no Glass left, nothing hides it. Making it solid would turn your thigh skin flat (no skin texture).
- `ServerStorage._Builders` scripts still make Glass if someone runs them again.

## Owner to-do (urgent)
1. File > Save to Roblox, then **File > Publish to Roblox** (live players from ads). I can't publish from here.
2. Download a Copy to `Documents\GymArc_backups\GymArc_2026-11-02.rbxl`.
3. Join live and check your character (and a friend's) from outside a gym window. If anyone is still flagged after this, tell me the time; it would mean the check looks at something else.

Screenshots: `GYM ARC/Screenshots/hotfix_clothes/`
![[GYM ARC/Screenshots/hotfix_clothes/01_server_body_BEFORE_bare.jpg]]
![[GYM ARC/Screenshots/hotfix_clothes/02_server_body_AFTER_tank_shorts.jpg]]
![[GYM ARC/Screenshots/hotfix_clothes/03_powerlifting_window_as_GLASS_test.jpg]]
![[GYM ARC/Screenshots/hotfix_clothes/04_powerlifting_window_fixed.jpg]]
![[GYM ARC/Screenshots/hotfix_clothes/11_hall_statue_tank_shorts.jpg]]
