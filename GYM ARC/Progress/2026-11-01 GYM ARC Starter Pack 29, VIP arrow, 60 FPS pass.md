---
date: 2026-11-01
tags: [gymarc, progress, performance]
---
# GYM ARC - 1 Nov: Starter Pack 29 R$, tutorial arrow to the VIP Gym, 60 FPS pass

Back to [[00 GYM ARC Home|GYM ARC Home]]. Feature: [[GYM ARC - Performance]].

## Starter Pack price
- Owner changed the Starter Pack product to 29 R$ on the Creator Hub. `Config/Monetization` StarterPack `price = 29` (was 49), so every in-game price shows 29.

## Tutorial arrow led new players into the VIP Gym (owner: dislikes)
- Owner (tested on an alt): "the tutorial arrow leads to the pro gym chest press and it looks like they're forced to buy vip".
- Cause: the VIP Gym (moved next to the Starter Gym entrance 31 Oct, widened 1 Nov) has copies of the starter machines with the same MachineIds (FlatBench, InclineBench, CrunchBench, dumbbell spots). `Shared/GoTo.Find` picks the NEAREST machine of the asked type; the VIP copies are ~20 studs from the spawn, the Starter Gym's ~80, so the tutorial / GO TO arrow led into the VIP Gym (VIP pass only).
- Fix (`Shared/GoTo`): a club machine only counts for a player who can use it: Club "VIP" = Pass_VIP, any other Club (Golden Era) = never, Members (no club) = GroupMember. Applies to the tutorial arrow, every GO TO, the "all busy" fallback and the server teleport (GoToService passes the UserId). "Gym:<name>" targets skip club machines too.
- Tested: from the spawn with no passes, FlatBench / InclineBench / CrunchBench / DBCurl -> Workspace.Gym (the Starter Gym).

## 60 FPS pass (owner: "we need to optimize the game more in gym arc, all devices need to be 60 fps")
Already in place (earlier passes): MobilePerfClient, LightAreaClient (55 studs low end / 110 PC), LightShadowsClient, NpcCullingClient, BlobShadowClient, BackdropClient, the remodel (10,852 parts -> 1,391 meshes), plate labels.
Measured now (Studio, starter area): 21,489 parts in the world (3,122 meshes), 634 lights (455 on, 17 with shadows), 772 SurfaceGuis, 45 emitters, 26 humanoids; Lighting: Bloom + ColorCorrection, GlobalShadows on. Hiding the town, the gyms, the NPCs, shadows or the UI each saved only ~2-6 ms of render time: no single big cost left, so the fix is drawing less world on slower devices.
- `Shared/LowEnd`: "slow" now = under **55** FPS for **4** s (was 40 / 5): every device that misses 60 gets the existing light settings (no world shadows / bloom / DoF / sun rays, closer signs, fewer particles, near lights only, NPC culling at 70, ...), not only phones.
- New `WorldLodClient` (StarterPlayerScripts): on a low-end / slow device small props (< 6 studs) past 140 studs and medium pieces (< 25 studs) past 260 studs aren't drawn (LocalTransparencyModifier, this device only); still under 45 FPS after 10 s -> 90 / 170 studs. Never: characters / NPCs, machines, see-through parts, anything 25 studs or bigger. Measured from the camera (the menu camera too). Works with the other scripts that use the modifier (Pro Gym door, Powerlifting shutters, NoHalfFade: it restores their value). Studio test: TestLodTier 2 hid 9,372 pieces, render CPU 20.6 -> 16.4 ms in the menu view.
- Studio's own frame rate under remote control is no guide (~15-40 FPS, noisy); the real check is the Performance dashboard (Creator Hub > Analytics > Performance, by device) after publishing.
- Owner to do (biggest lever left, scripts can't change it): Workspace > StreamingTargetRadius 256 -> 160 (the compact town is almost all inside 256).
