# Break A Bed: Decisions

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

- **2026-10-10: Everything is built from code.** Beds, health bars and pads are made by `BedServer` + `BedBuilder` when the game starts. No hand-built models, so all tuning lives in `BedConfig`.
- **2026-10-10: Coins are split by damage.** Everyone who hit a bed gets a share, so players can work together on big beds.
- **2026-10-10: Rebirth design.** Coins reset to 0. You get +1 damage and +50% coins per rebirth. Cost starts at 500 and grows 2.5× each time. The numbers are a first guess and still need balancing.
- **2026-10-10: Old "Royal Bed" renamed "Canopy Bed".** The new tier row has its own Royal Bed, so the starter-area canopy bed was renamed to avoid two beds with the same name.
- **2026-10-10: The tier row is one row of 7 beds** behind the starter area: Cardboard, Wooden, Cozy, Royal, Golden, Diamond, Cosmic. Golden, Diamond and Cosmic glow.
- **2026-10-10: The game lives in the Studio place "Break A Bed"** (placeId `116443177548785`). Claude puts scripts in through the Roblox Studio MCP.
- **2026-10-10: Notes go in this vault** (`ProjectOne`), folder `Break A Bed` only. City Legends notes stay in `City Legends`.
