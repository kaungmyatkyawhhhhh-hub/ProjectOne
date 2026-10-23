---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 31 Shops rework (Coach Dex shop, PUMP SHOP specials) + UNDISCOVERED items

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Owner decisions about shops and the inventory. Follow CLAUDE.md Speed rules. Black + Gold kit, mobile first. Never undo the owner's manual Studio changes. Keep players' owned items and saves (migrate, never delete).
Owner screenshots: C:\Users\kaung\Downloads\gym_arc_shops_refs\ (pumpshop_inside, inventory_alters, next_alter_pill).

NAMING RULE: in every shop the tabs are just called "SUPPLEMENTS" and "GEAR" (plus ALTERS / DNA LAB where listed). Shops differ by their items, not by tab names.

1) COACH DEX = THE MAIN SHOP (like the Gym League shop)
- Coach Dex is no longer a quest NPC. Talking to him opens his shop. Quests stay available from the Quests button in the HUD (move anything that only worked through Coach Dex there). He can still say his tutorial lines.
- His shop has 3 tabs: SUPPLEMENTS (the normal boosts: Protein Shake, Creatine, Protein Powder, Supplements, Pre-Workout), GEAR (Basic and Pro levels of belt, wraps, straps, sleeves), ALTERS (the alter ladder: current, next with its goal progress and bonus, the ALTER button when ready).
- Coach Dex is ONLY in the Starter Gym (owner, 21 Oct). Don't put copies in other gyms. Don't add a side-menu button for him (the side menu stays at 8 buttons). Players in other gyms can reach him with a small "Coach Dex" link inside the Shop panel that teleports them to his counter (cooldown 10 s).

2) PUMP SHOP = SPECIALS ONLY, ONE SHOP
- Inside the PUMP SHOP: ONE counter and ONE panel (not separate Apparel / Gear / Supplements counters). Remove the extra counters, signs and the "Cold Shakes" fridge-shop; keep it as nice decoration if it looks good, or remove it.
- Its panel has 3 tabs: SUPPLEMENTS (special ones), GEAR (special ones), DNA LAB.
- Special supplements (stronger, rarer, pricier; all numbers in config): Mass Gainer (+50% Growth Spurt/alter progress, 10 min), Elite Pre-Workout (+50% rep speed, 10 min), Whey Isolate (+50% EXP, 15 min), BCAA Recovery (+100% stamina regen, 15 min).
- Special gear: the Elite level of the 4 gear pieces, plus a new top level "Champion" (+20%, a gold look) with a big price.
- No ALTERS in the PUMP SHOP. Apparel is removed from sale for now (players keep what they own).

3) COCONUT STAND
- It's floating: put it on the ground (raycast down, fix its pivot), check every copy.
- It sells ONLY Coconut Water (one simple panel, buy x1 / x5).

4) REMOVE THE SMOOTHIE STAND / SMOOTHIE BAR EVERYWHERE (all gyms and the town). Fill the space with something that fits (plants, a bench, more gym floor). Remove its scripts/prompts too.

5) INVENTORY: UNDISCOVERED ITEMS (curiosity)
- Anything the player hasn't unlocked and isn't next in line shows as UNDISCOVERED: a dark tile, a black silhouette or "?" instead of the icon, the name replaced by "???", and a small gray "UNDISCOVERED" label. No name, no description.
- ALTERS: owned = full tile (WEAR / WORN); the NEXT alter = shown (name, look, goal progress, "NEXT"); everything after that = UNDISCOVERED. Tiers without textures yet: hide them completely instead of "Coming soon".
- Same rule for AURAS and TITLES (titles already use "???"; match the new UNDISCOVERED style) and TRAINERS (the Secret one stays "???" until owned).
- Show a count per tab: "Alters 3 / 30 discovered".
- When something new is unlocked: its tile flips from UNDISCOVERED to revealed with a small gold burst the first time the player opens that tab, plus a red dot on the tab.

6) "NEXT: TANNED" PILL (HUD) MATCHES THE NEXT ALTER
- Restyle the pill with the next alter's theme from prompt 22 (accent color, a thin strip of its background art, its title gradient on the name). E.g. NEXT: TANNED = bronze sunset strip with gold rays, the name in the orange-gold gradient. It changes automatically for each next alter.
- Keep it readable: dark base, the progress "55%" in white, "TAP FOR WHAT TO TRAIN" in small gray.

Screenshots: Coach Dex shop in the Starter Gym (each tab), the PUMP SHOP panel and inside view, the coconut stand on the ground, inventory alters tab with UNDISCOVERED tiles, and the NEXT pill. Short progress note in the vault.
```
