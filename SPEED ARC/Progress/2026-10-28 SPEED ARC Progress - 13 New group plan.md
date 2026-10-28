---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - 13 New group: the plan (step 1 + 2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Prompt: [[2026-10-28 SPEED ARC Prompt - 13 New group and publish]] · Before: [[2026-10-28 SPEED ARC Progress - 12 UI art kit applied]]

**Status: plan only, nothing changed. Waiting for the owner.** Every id below was checked with Roblox (`MarketplaceService:GetProductInfo`) on 28 Oct.

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
