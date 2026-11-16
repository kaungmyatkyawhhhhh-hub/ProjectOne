---
tags: [mm-outfit-catalog, build-log, audit]
created: 2026-11-16
---
# Audit fixes (all 10 + 1 small one)

- **Source:** the ponytail-audit of the game scripts (16 Nov). Not saved or published by Claude.
- **Backups:**
  - `ServerStorage.ScriptBackups.pre_AuditFixes_16Nov` (OutfitShowcaseServer, OutfitViewer, PhotoBooth, Config).
  - Retired scripts are in `ServerStorage.ScriptBackups.retired_AuditFixes_16Nov`.

| # | Fix | Where |
|---|---|---|
| 1 | The per-piece **Buy** now goes through `ShowroomAction "Checkout"`, so the sale is recorded (stats, history, notice) | OutfitViewer |
| 2 | Profile load retries 4 times (1 / 2 / 4 s); a single DataStore hiccup no longer skips saving the whole session | OutfitShowcaseServer `playerAdded` |
| 3 | The Photo Booth hides other players twice a second, not every frame | PhotoBooth |
| 4 | Removed the old `RequestPurchase` / `RequestBuyAll` purchase remotes (they skipped recording) and the rate limiter only they used | OutfitShowcaseServer, OutfitViewer |
| 5 | Moved two disabled scripts out of the game: a free-model rain `Settings` script and `PenthouseWayfinding` | → retired backup folder |
| 6 | Removed the Buy-all glow rings, 3D base and shine that were always hidden (one flat face now) | OutfitViewer |
| 7 | Removed the unused layered-clothing code (`LAYER_ORDER`, the `IsLayered` branches) | OutfitShowcaseServer |
| 8 | New `ServerScriptService.SelfChecks`: Studio-only asserts that a repeated donation receipt counts once, weekly totals match, and old weeks get pruned | new |
| 9 | "Not owned" answers expire after 60 s (an item bought on the website mid-session stops showing a price) | OutfitShowcaseServer `owns` |
| 10 | The rate-limit list that never emptied went away with fix 4 | — |
| 11 | Removed the unused `Config.StageOrigin` | Config |

**Lines:** about −190 net (the SelfChecks script adds 21).

## Tested (Studio Play)
- **SelfChecks:** prints "donation receipts OK"; 0 console errors.
- **Viewer:** Buy all looks and reads the same ("Buy 2 items · R$ 120").
- **Per-piece Buy (real clicks):**
  - It opened a Checkout. Proof: a second request was refused with "Finish the open checkout first."
  - The prompt was cancelled with Esc; nothing was bought.
- **Remotes now:** ShowroomAction, PurchaseUpdated, GetOutfitInfo, ShowroomNotice.
- **Photo Booth:** opens and closes; the camera is restored.

## Not tested
- The profile-load retry and real purchase recording: both need the published game.
- The flush (profile save) maths still has no check: it lives inside the server script and isn't testable without splitting it out.
