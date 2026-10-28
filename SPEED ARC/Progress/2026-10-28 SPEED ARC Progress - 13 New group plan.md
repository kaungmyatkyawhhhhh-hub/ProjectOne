---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - 13 New group: the plan (step 1 + 2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Prompt: [[2026-10-28 SPEED ARC Prompt - 13 New group and publish]] · Before: [[2026-10-28 SPEED ARC Progress - 12 UI art kit applied]]

**Decision (owner, 28 Oct): COPY** (route B: Save to File, then Publish As a new experience owned by the new group; the old one stays in Myanmar Builders Club, set to private, not deleted). Nothing changed in the game yet. Every id below was checked with Roblox (`MarketplaceService:GetProductInfo`) on 28 Oct.

## 1. Every asset the game uses, and who owns it

| What | How many | Owner now | Must move? |
|---|---|---|---|
| Game passes (Auto Train, 2x Speed, 2x Coins, VIP, Extra Coach Slot, Extra Coach Slot 2, Trail Pack, Faster Rolls) | 8 | Myanmar Builders Club (33151111) | Moves **with the experience** if we transfer it (see 2). Only re-created if we publish a new copy. |
| Developer products (Small / Medium / Large Coins, 2x Speed 15 min, Starter Pack) | 5 | belong to the experience | Same as passes. |
| Pass / product icons | 13 | 33151111 (attached to the passes) | Only if the passes are re-created. PNGs: `Downloads\speed_arc_models\icons\`. |
| Clothing templates (Shirt SingletBlue / TeeGold / ZipBlack / VipTop, Pants ShortsBlue / SplitBlack / TightsGold / VipShorts) | 8 images | 33151111 | **Yes, re-upload** (images are what broke in GYM ARC). PNGs: `Downloads\speed_arc_models\clothing\`. |
| UI art kit sheets (`ui_buttons`, `ui_tiles`, `ui_icons`) | 3 images | not uploaded yet | **Upload to the new group** (`Games\SpeedArc\ui_kit\sheets\`). |
| Meshes in use (25 in `ServerStorage/Meshes`: shoes, kit, head items, shop / booth shells, coach board, arch, cone, lamp, food cart; plus the crowd fans x6, trees x3, bench, treadmill, starting block, flood tower, bleacher, gazebo, fountain) | ~41 | 33151111 | **Yes, re-import** into the new group (FBX files are in `Downloads\speed_arc_models\hub`, `locker`, `areas`: 51 files). Then I rebuild the 3 worlds. |
| Old meshes in `ServerStorage/MeshesV1_Backup` | 10 | 33151111 | No: not used. (Can be deleted later, if you say so.) |
| Music + sound effects | 27 | APM / ProSoundEffects / other Creator Store creators (public) | No: library audio works in any experience. |
| Sky textures (sun, moon, skybox) | 5 | Roblox's default sky | No. |
| Walk / run animations | 2 | Roblox (user 1) | No. |
| Notification strings (`daily_ready`, `new_league`, `weekly_top`) | 3 | the experience | Move with the experience if transferred; re-made only for a new copy. |
| Saves (data stores) | - | the experience | Stay if transferred (no real players yet anyway). |

Nothing uses InsertService, private modules or packages, so the transfer has no extra blockers.

## 2. Two ways to move it

**A) Transfer the experience (recommended).** Roblox allows group-to-group transfers since 3 Dec 2025 (Configure > Settings > "Initiate ownership transfer"). It keeps the place id 134701616695802, the URL, the passes, products, notification strings and saves. The game goes private and its servers close while it moves (fine: it's not launched). After a transfer it can't be transferred again for 30 days. Roblox's docs don't say clearly that passes move with it (forum reports say they do), so I check every pass and product owner right after.
**B) Publish As a new experience** (only if the transfer button isn't there): a new place id, re-create all 13 passes / products + icons, re-make 3 notification strings, and the old copy in Myanmar Builders Club is set to private (not deleted).

Either way the **images and meshes** are re-uploaded into the new group (your rule: assets belong to the group that owns the game).

## 3. What you click (route A)
1. **Create the group:** roblox.com > Communities (Roblox's new name for groups) > Create. Name it, e.g. "SPEED ARC Studio" (no real brands). Tell me the price it shows (it has been 100 Robux).
2. **Start the transfer:** create.roblox.com > Creations > switch to **Myanmar Builders Club** > SPEED ARC > Configure > Settings > **Initiate ownership transfer** > tick the details > Next > pick the new group > type the experience name > Initiate transfer.
   - If you don't see "Initiate ownership transfer", stop and tell me: we use route B.
3. **Accept it:** open the transfer notification (or the experience page as the new group) > tick the details > Next > type the name > **Accept transfer**. Wait a few minutes, then tell me.
4. **Uploads to the new group, one at a time, each one you approve first:**
   1. The 3 UI sheets: Creator Hub > switch to the new group > Development Items > Decals > Upload each one > send me the 3 ids.
   2. The 8 clothing templates (`Downloads\speed_arc_models\clothing\`), same way > send me the 8 ids.
   3. The meshes: in Studio, **Window > Asset Manager > Bulk Import**, pick the FBX files from `hub`, `locker` and `areas`, and set **Upload to: the new group**. They land in Workspace; I move them into `ServerStorage/Meshes` and rebuild.
5. Then I do step 3 of the prompt: swap every id in Config, check each one with Roblox (name, price, owner = new group), rebuild the worlds, test purchases in Studio, check nothing points to group 33151111.

## Sources
- [Experience ownership transfer (Creator Hub docs)](https://create.roblox.com/docs/en-us/projects/experience-ownership-transfer.md)
- [Group-to-group transfers announcement, 3 Dec 2025](https://devforum.roblox.com/t/managing-your-group-revenue-and-experience-ownerships-just-became-a-lot-easier/4114133)
- [Asset privacy (Creator Hub docs)](https://create.roblox.com/docs/en-us/projects/assets/privacy)

## Route B (chosen): the owner's checklist
1. [ ] Create the new group (Communities > Create). Price shown: ____
2. [ ] Studio (SPEED ARC): File > Save to File > `SPEED ARC 2026-10-28 before group move.rbxl` (backup).
3. [ ] File > Publish to Roblox As > **Create new experience** > Owner = the new group > name it **+1 Speed Evolution** (owner, 28 Oct; SPEED ARC stays the brand underneath) > Create. Then send me the new place id.
4. [ ] Create the 8 passes in the NEW experience (Creator Hub > the new experience > Monetization > Passes), each with its icon from `Downloads\speed_arc_models\icons\`, price set, on sale:

| Pass | Price | Icon | Description |
|---|---|---|---|
| Auto Run | 249 | Pass_AutoTrain.png | Treadmills step for you 3x faster, all by themselves. |
| 2x Speed | 249 | Pass_2xSpeed.png | Double SPEED from every step, forever. |
| 2x Coins | 149 | Pass_2xCoins.png | Double coins from walls, races, steps and rewards. |
| VIP | 299 | Pass_VIP.png | +10% coins, VIP tag, VIP kit, VIP trail, VIP name style and a gold chat name. |
| Extra Coach Slot | 99 | Pass_ExtraCoachSlot.png | Equip one more coach (3 slots). |
| Extra Coach Slot 2 | 149 | Pass_ExtraCoachSlot2.png | Equip one more coach again (4 slots). |
| Trail Pack | 199 | Pass_TrailPack.png | 4 trails: Lightning, Rainbow, Comet and Neon Wave. |
| Faster Rolls | 99 | Pass_FasterRolls.png | Skip the roll animation and roll 3 coaches at once (same odds). |

5. [ ] Create the 5 developer products (Monetization > Developer Products):

| Product | Price | Icon | Description |
|---|---|---|---|
| Small Coins | 25 | Product_CoinsSmall.png | 20 minutes of coins |
| Medium Coins | 99 | Product_CoinsMedium.png | 2 hours of coins |
| Large Coins | 249 | Product_CoinsLarge.png | 6 hours of coins |
| 2x Speed 15 min | 25 | Product_2xSpeed15.png | Double SPEED per step for 15 minutes of play |
| Starter Pack | 49 | Product_StarterPack.png | 1 hour of coins + 2x SPEED for 30 min + gold Canvas Runners + the STARTER title. Once! |

6. [ ] Send me the 13 new ids.
7. [ ] The 3 notification strings (new experience > Engagement > Notifications): `daily_ready` "Your day {streak} streak reward is waiting in SPEED ARC!", `new_league` "A new league just opened in SPEED ARC. Come race!", `weekly_top` "You finished top 3 this week! Your title is waiting."
8. [ ] Uploads to the new group, one at a time (I list each first, you approve): 3 UI sheets, 8 clothing images, then the meshes (Studio > Asset Manager > Bulk Import, Upload to = the new group). Send me the ids.
9. [ ] Old experience (Myanmar Builders Club): Configure > set to **Private**. Don't delete it.

## 28 Oct: the new group
- The owner made it: **P&L Studios XP**, group id **947215423** (roblox.com/communities/947215423). (The 100 Robux create page and an emblem draft, `Downloads\speed_arc_models\group\SpeedArc_Group_Emblem.png`, are no longer needed.)
- Game name (owner, 28 Oct): **+1 Speed Evolution**, SPEED ARC as the brand underneath.
