---
tags: [city-legends, ggfest, laptop, checklist]
created: 2026-11-19
---
# Laptop in Yangon: setup and GGFest publish checklist

The owner left for Yangon on 19 Nov 2026. The home PC keeps running the agents (P4, P6, P8 move-in). The laptop has 16 GB RAM.

## 1. When you arrive (about 15 min)
1. **Vault:** open the vault in Obsidian on the laptop and pull (Obsidian Git), so you have every note.
2. **Studio:** open Roblox Studio and sign in. Open **City Legends** from your creations. It's Team Create, so it's the same place the PC is working on.
3. **Don't edit in Studio while the PC agents are working**: only look and test. (The home PC may be off after a power cut; then nothing is working on it.)
4. **Optional, for Claude on the laptop:** install the Claude desktop app, open this vault folder, and install the Roblox Studio MCP plugin in Studio.

## 2. Before GGFest (Saturday), test first
In Studio, press **Play** and check:
- Spawn by Myanmar Plaza, the loading screen and menu, a drive around P1–P3 and P7.
- **JOBS** tab: take Tea Shop, and get a paycheck.
- **DEALER** button, **SHOP** button, the plates screen.
- **Settings → Language → မြန်မာ**: does it look right? Note any translation you'd change.
- Phone view: in Studio, use the **Device** emulator, pick a phone, and check that the driving buttons fit.

If the PC is still in the middle of a district swap, wait until it says done. The `rebuild_progress.json` in `Games/CityLegends/build/city_1to1/` says which step it's on.

## 3. Publish (makes it live for players)
1. In Studio: **File → Publish to Roblox**.
2. Open the live game in the **Roblox app** on the laptop. Test the same things, plus:
   - **One real Robux test buy** (the cheapest: Spin, 25 R$), to check that the purchase is given.
   - The full map zooms out to all of Yangon.
   - The car spawns and jobs pay.
3. On a **phone** (ideally a cheap Android), run the low-end check:
   - Settings → Graphics → Performance should say AUTO.
   - Type `/console`, then open the Memory tab (Client). Note **Total** and **GraphicsTexture**, and the FPS at spawn and at Sule.
   - Send the numbers to Claude.

## 4. At the booth
- Plug the laptop in. Bring a phone hotspot in case the venue Wi-Fi is bad.
- GGFest content (YCC, the GG Quest, the wrap and plate) switches on by itself on 21–22 Nov, Myanmar time.

## If something is broken
Tell Claude what you saw, with a screenshot. The home PC agents can fix it if the PC is still on.
