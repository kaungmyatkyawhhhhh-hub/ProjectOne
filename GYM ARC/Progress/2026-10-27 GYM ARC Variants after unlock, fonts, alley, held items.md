---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Variants after unlock, fonts, alley skating, invite, inventory, held items (prompt 77)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 77 Variants after unlock, fonts, alley skating, invite, inventory]].

- **Variants only after their alter (option 3):** a variant's button says "UNLOCK <ALTER> FIRST" until the alter is reached (or its skin was owned before); the buy taps refuse too (`AltersPanel`). The Store SKINS tab is off (`StoreClient` SKINS_TAB = false); variants sell in Inventory > Alters and Coach Dex > ALTERS.
- **No more coin alter looks:** `Config/Alters.SkinsForCoins = false`; ActionService BuyAlterSkin does nothing; Coach Dex shows no coin price tags or BUY. Skins bought before stay owned.
- **Premium font** (Montserrat Black Italic, `KeepFont`) on WEAR / WORN / BUY in Inventory and WHAT TO TRAIN / OWNED / MY SKINS / WORN / WEAR / BUY in Coach Dex.
- **Skating in the alley** between the Starter and Powerlifting gyms: `Config/Town.SkateExtra` (x -64..-45, z -98..-2), read by `Town.IsOutdoors` (SkateClient + SkateService). Checked: SKATE button shows there.
- **INVITE +10%** button: words 13 -> 14 (Roblox rounds 14.3), icon 13 -> 15 (`FriendClient`).
- **Inventory not squashed:** `Kit.Modal` takes `maxHeight`; the Inventory grows from 290 up to 380 tall when the screen has room under the top bar (stays 290 on small phones). Shows 2+ rows of alter tiles now.
- **Held items are real models** (owner: "the item is just a cylinder ... equip the real model" / "arent most of the item have models already like in the pumpshop"): `ItemService` buildHeld: supplements = the PUMP SHOP shelf Tub + Lid meshes (`ServerStorage.HeldItems`), lid and band in the item's colour, its picture on the front; Shake / Coconut Water = a shaker bottle (clear bottle, coloured drink, black cap + spout, label). Scaled with the hand. The shop's only product meshes are the tub and lid (the other "Remodel" meshes are benches / lamps / trees).
- Note: the test save owns and wears Inferno (over Shredded): the owner's own test purchase; left as is.
