# Prompt: replace the casino with a rewards centre (daily rewards and other things to claim)

_For Claude Code with Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extra features: do what's written here, and ask the owner if something is unclear._

## What the owner wants (2026-11-03)
- **The casino goes.** In its place, on the casino square, stands a **rewards centre**: a building where players **claim their daily reward** and **the other rewards they've earned**.
- The square, the valet bay and the supercar nightlife round it stay as they are (see `Make the Monaco map look real (from the drive video).md`).

## Before you start
- Read:
  - `CLAUDE.md`;
  - `Roblox Playbook/Roblox Playbook - Rules for every game.md`;
  - `Games/CityLegends/CLAUDE.md`;
  - `City Legends/City Legends.md`;
  - `City Legends/Prompts/Remodel the venues.md` (realism rules, Toolbox use, keep it fast).
- Call `list_roblox_studios` and use the Studio named **City Legends** only. Save a backup first. The place is on Team Create.
- Read the code that's there now:
  - `src/server/Casino.lua`, `Luxe.lua` (casino VIP, the casino vault heist), `LuxeClient.lua`;
  - `src/server/Goals.lua` (the 7-day streak with a car on day 7, the Legends Path milestones), `GoalsClient.lua`;
  - the `ClaimDaily` remote in `Main.server.lua`;
  - the penthouse wall safe (`Towers.lua`, daily rent);
  - the hotel suite income (`Hotel.lua`);
  - `MainMenu.lua`.

## Step 1: remove the casino
- Remove the casino building and everything that only the casino uses (scenery, the VIP card, the casino vault heist, its prompts, minimap icon, chauffeur stop, map symbol), cleanly, with no leftover errors or dead remotes.
- **Before deleting anything with player data or money** (the Black VIP card players may own, the casino heist), list it for the owner and ask what to do with it: keep it working somewhere else, or remove it and refund. Wait for the answer.
- Keep the casino square, its gardens, fountain, valet and traffic loop.

## Step 2: build the rewards centre in its place
- A grand, realistic building on the square, in the same Monaco luxury style as the other venues (see `Remodel the venues.md`; Toolbox models allowed, cleaned and made our own). Name: **"Legends Rewards"** (or the owner's choice). Gold letters, no logo, no neon.
- Inside: a hall with **claim desks / counters**, one per kind of reward (below), each with a ProximityPrompt (E / tap) that opens a clean claim panel in the game's UI style.
- On the map, minimap, chauffeur stops and fast-travel map: the casino's spot becomes "Legends Rewards".

## Step 3: what players can claim there
Only the rewards the game already has, gathered in one place:
1. **Daily reward:** the existing **7-day streak** (rising cash, **a car on day 7**), from `Goals.claimStreak`. Show the 7 days, which one is today, and the time until the next claim.
2. **Legends Path milestones:** the existing milestone / goal rewards that are done but not claimed yet.
3. **Penthouse rent:** the daily rent from the penthouse wall safe (also claimable here, for owners).
4. **Hotel suite income:** the earned suite money (also claimable here, for owners).
5. **Any other reward that already exists in the code** that a player has to claim (look for them, list them for the owner, and add each one the owner agrees to).

**If the owner names other things to claim, add exactly those.** Don't invent new reward types.

## Rules
- **The server decides everything:**
  - checks the time / cooldown and what's really owed;
  - saves before paying;
  - never pays twice (one claim per player at a time, with a lock);
  - rate limits the remotes;
  - checks the player is at the desk.
- The rewards can still also be claimed where they are now (menu, penthouse safe...). This building is an extra, central place, not the only one, unless the owner says otherwise.
- **Feedback on every claim:** a sound, an effect and the amount shown (Playbook).
- **A "rewards ready" dot** on the HUD / menu when something is waiting, with a waypoint to Legends Rewards.
- Old saves keep working (players don't lose streak days or money).
- No gambling of any kind (no spins with random paid prizes).

## Check before you say done
- 2-player test:
  - claim each reward;
  - try to claim twice (refused);
  - streak day changes;
  - day 7 gives the car;
  - an old save still works.
- No console errors. The casino is fully gone (search the code for leftovers).
- Screenshots: the building outside (day + night), inside, each claim panel, phone size.
- FPS before and after.
- Lune tests and `luau-lsp analyze` clean.
- Save, commit, push, and note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- what was removed;
- what's in Legends Rewards;
- screenshots;
- anything you need the owner to decide (the VIP card, the casino heist, more things to claim).
