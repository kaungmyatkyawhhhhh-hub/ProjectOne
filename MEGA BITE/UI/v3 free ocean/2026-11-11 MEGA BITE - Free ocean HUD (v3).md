# MEGA BITE - Free ocean HUD (v3) - 11 Nov 2026 (autopilot, after midnight)

Owner, as a player: the boxed HUD "feels like a trap than a freedom". New rule: **the ocean is the game; the HUD only speaks when it has news.**

![[before_v2_boxed.jpg]]
![[after_v3_at_rest.jpg]]

## What changed (MB_HUD rewritten; boxed v2 backed up in ServerStorage.MB_HUD_v2_boxed_backup)
- **No dark boxes.** SIZE and EXP are icons + numbers floating over the water (thick ink outline), one slim row top-left.
- **Fades:** the NEXT bar + CARRYING fade in when they change and out after ~3 s. NEXT stays up in the last 20% (anticipation); CARRYING stays while the bag is FULL (gold + gentle pulse).
- **Minimap:** small round see-through disc (92 px), N on the rim.
- **Quest:** a quiet chip (scroll + distance) under the minimap; the words only slide out when the quest is new (or on tap).
- **STORE + INDEX:** small, same blue base, no counters on them; red dot only for unseen new fish.
- **DART** = the one hero button; no permanent READY text, the seconds appear big in the middle only while it recharges.
- **Abilities hidden until earned:** FRENZY pops in with a bounce when you become a Piranha + "NEW ABILITY: FRENZY!".
- **Toasts = floating words** at the top centre. Rewards/discoveries in gold/green (with a chime); zones are calm words ("OPEN SEA · x2 EXP", "SAFE REEF"); no "RUN!" text when hunted (the edge arrow + sound do it); "BAG FULL!" without orders.
- **Windows slide in from the side** and the dim is light (0.72), so the sea stays visible behind the Store / Fish Index.

![[after_v3_exp_and_full_bag.jpg]]
![[after_v3_evolve_ability_unlocked.jpg]]
![[after_v3_store_window.jpg]]

## Notes
- Megalodon texture (asset 84306710672621) is still "being generated" on Roblox, so the store preview shows grey for now.
- To check on a real phone: thumb reach of the small STORE/INDEX, readability of floating text over the bright sand.
- Script source: MB_HUD_v3_free_ocean.lua (this folder).
