# Gym Lift Progression (Roblox prototype)

**Track:** Design & Programming, option 2 (progression feature from a simulation game).
**Inspired by:** the lifting loop of gym simulators like *Gym League* and *Muscle Legends* (both well over 10k CCU).

## What I built
A repeatable **lift → earn → upgrade → grow** loop for any number of players in one server:
- **Train** at one of 6 Overhead Press stations (ProximityPrompt). Each rep is a **timing mini-game**: tap, click or press Space while the moving line is in the green zone.
- A rep gives **Strength** (permanent, drives rank and body size) and **Cash** (spent on upgrades). A **perfect** rep gives double, and perfects in a row build a **combo** (+10% each, up to +100%).
- **Upgrade weights** (5 kg → 160 kg). Each tier doubles the gain per rep, and the panel spells out the effect ("x4 → x8 per rep"). Heavier weights also make the line faster, so better rewards need better timing.
- **Ranks** (Twig → Olympian), with a progress bar to the next rank.

**Visible to other players:** the barbell moves on the server with every rep, with sound and sparkles on perfects. The plates change size and color with your weight tier. **Your body grows** with Strength (R15 scale, tweened). An overhead tag shows rank, Strength, weight and a 🔥 combo, a sign over each station shows who is using it, rank-ups are announced to the whole server, and leaderstats are on.

## Key decisions
- **The server owns every number.** It re-computes where the timing line was when the player tapped (a shared deterministic needle plus the synced server clock), so "perfect" can't be faked. It also enforces the rep cooldown and validates purchases.
- **Two currencies.** Strength is never spent, so buying an upgrade never shrinks your body or rank. Cash is the spendable resource.
- **Skill on top of grind.** The timing bar and combo give the classic tap loop a real input decision, and heavier weights trade speed for reward.
- **Everything is in code** (the world is built at runtime) and split into modules: `GymConfig` (all tuning), `GymUtil` (shared math), `GymWorld`, `PlayerData` (DataStore with a safe fallback), the `GymServer` script and the `GymClient` script.

## With more time
Real lifting animations and custom sounds, more exercises (bench, squat) tied to different muscles, a spotter / co-op rep for two players, server leaderboards, mobile UI polish, and analytics to tune the weight curve.

**Run it:** open `GymLiftProgression.rbxlx` in Studio (File → Save As .rbxl). Test with *Test → Clients and Servers → 2 players*. Avatar type: R15.
