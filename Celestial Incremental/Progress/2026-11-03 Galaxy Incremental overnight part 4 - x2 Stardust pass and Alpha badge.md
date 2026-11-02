---
date: 2026-11-03
tags: [galaxy, store, pass, badge, progress, overnight]
status: built and tested in Studio with placeholder ids; not published
---
# Galaxy Incremental - overnight part 4: x2 STARDUST pass + ALPHA badge (3 Nov, Claude Code)

From the overnight run (part 4), the design note section 9 (monetization), and [[2026-11-02 Galaxy Incremental - Launch plan (test, alpha, full launch)]].
Screenshots: `Progress\screens\overnight\p4-*`.

## Creator Hub: what you must create (P&L Studios XP, the Galaxy Incremental experience)
Put each new id in `ReplicatedStorage.Galaxy.GameConfig`. That is the ONE config for every Creator Hub id; they are all placeholders (0) now.

| Type | Name | Description | Price | Image | Goes in |
|---|---|---|---|---|---|
| Game pass | **x2 Stardust** | All your stardust x2, forever. Stacks with potions and Star Surge. | **249 Robux** (design note 9) | 512x512, the stardust star with "x2" (passes show as a circle) | `Passes.X2Stardust.id` |
| Badge | **Alpha Player** | You played Galaxy Incremental during the Alpha. Thank you! | (badges cost nothing to make: the first 5 a day are free) | 512x512 | `Badges.AlphaPlayer` |

- The store reads the pass price live from Roblox, so a later price change in Creator Hub shows by itself.
- No images were made for these two (see the open question in the overnight summary).

## x2 STARDUST pass
- **The STORE window** (hotbar E, key E; shots p4-01, p4-02):
  - a v12 window in the Store's red;
  - the pass card: the stardust icon with an "x2" tag, "x2 STARDUST", what it does, and the price button;
  - a CODES button underneath (opens the Codes window).
- **The price button:**
  - green "R$ 249" when it can be bought;
  - grey "OWNED" when you have it;
  - grey and inactive while the pass id is still 0 (no prompt, an error sound).
- **Buying:** the client asks the server, and the server shows Roblox's purchase prompt.
- **Ownership** is checked on join (`UserOwnsGamePassAsync`, 3 tries) and when a purchase finishes. The x2 starts at once, no rejoin.
- **The x2 sits in the income formula once** (`GalaxyEconService.incomeOf`), next to the potion and Star Surge multipliers.
  - Tested: income 1 → 2 with the pass, → 4 with the pass + an x2 potion.
- **Analytics:** custom events `PassPromptShown` and `PassBought`.

## ALPHA PLAYER badge
- **`GameConfig.AlphaActive = true`:** every player who joins during the Alpha gets:
  - `alphaPlayer = true` in their save (for the launch title), plus the `AlphaPlayer` attribute;
  - the badge, once it has an id. The save remembers when Roblox confirmed it, so it retries on the next join if Roblox was down.
- **At full launch:** set `AlphaActive = false`. Who already has the flag keeps it.

## Tested (Studio Play)
- **Store window:** no pass id (grey price, does nothing) and owned (OWNED), using the Studio switch `TestOwnX2`, now removed.
- **The pass x2:** income doubled; with a potion too, x4.
- **The Alpha flag:** set on join.
- No errors.

## Not tested
- **A real purchase prompt and a real badge award:** both need the real ids. The code paths are Roblox's standard calls, wrapped in pcall.

## Code
- **New:**
  - `ReplicatedStorage.Galaxy.GameConfig`
  - `ServerScriptService.GalaxyStoreService`
  - `StarterPlayerScripts.GalaxyStore`
- **Changed:**
  - GalaxyEconService: pass x2 in income, alphaPlayer / alphaBadge in the save
  - GalaxyHUD: E = Store
  - GalaxyCodes: its own side key, so the Store and Codes don't overlap
- **Vault copies:** `Code\friends-test\`.
