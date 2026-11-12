# MEGA BITE - Combat v1 (health for sharks, fish and predators)

Date: 13 Nov 2026 (built while the owner was away, long work order). Status: built in Studio, tested in Play, NOT published.

Owner's words: "make like a health system where the sharks damage you and not die instantly and also a health system for npcs too where u can damage them and not eat instantly if theyre tanky but if its tanky or deal high damage or glass cannon, the exp must be equal to the effort they put in into beating the enemy. also they get exp on every hit and not just when they finish eating so that people cant like steal on the final hit."

## What the player sees
- **Your HP bar** shows under the NEXT UP card whenever you are hurt (and always in the Red Trench). Toasts move down below it.
- **A predator's lunge hurts instead of eating you.** One lunge never takes more than 45% of your max HP, so it is always at least 3 hits from full. At 0 HP you are chomped back to the Safe Reef (as before, you lose nothing). HP comes back after 6 s without a hit (8% per second).
- **Fish have HP.** A fish you can swallow whole still goes in one bite. A bigger fish (up to 6 bites) has a GOLD outline and a badge with the number of bites it needs. Each bite pays its share of the fish's EXP at once, the fish wobbles, shows a small HP bar and bolts for 2 s. Left alone for 10 s it heals. More than 6 bites = padlock (too big).
- **Predators have HP and a name tag + HP bar** when you are strong enough to fight them (12 bites or fewer). Gold outline = you can fight it and it can't eat you; red outline = it can eat you.
- **Biting a predator:** "-164" damage number, stars and "+EXP" on every bite. The predator bolts away (0.85 s), then turns back and hunts the biter for 12 s. While it glows red (wind-up or lunge) a bite does not stop the lunge, so greedy biting costs HP. DART still dodges.
- **Beating one:** "TAKEDOWN!" pop, it is gone for 40 s, then a new one arrives. A predator left alone for 15 s heals to full.

## The numbers (all in GameConfig.Combat)
| Thing | Rule |
|---|---|
| Your HP | 100 x 1.55^(evolution - 1): 100, 155, 240, 372, 577, 894, 1386 |
| Your bite power | (eat length x 0.8)^2 |
| Fish HP | length^2 (so a fish at exactly your edible size = one bite) |
| Fish EXP per bite | fish EXP x zone x passes x (damage / max HP) |
| Predator HP | 3 x length^2: Hunter Barracuda 768, Reef Prowler 1505, Big Chomper 3696 |
| Predator damage | Hunter 55, Prowler 115, Chomper 240 (capped at 45% of your max HP) |
| Predator EXP pool | HP x (0.5 + damage / 100) x 0.1: Hunter 80, Prowler 248, Chomper 1065 |
| Effort rule | if you need fewer than 4 bites, the pool is scaled down (never under 25%) |
| EXP per bite on a predator | pool x (damage / max HP) x effort x passes |
| Cooldowns | 0.4 s between bites on big fish, 0.6 s on predators |

Why these: the EXP pool grows with how tanky the creature is AND how hard it hits, and every bite pays its own share, so the last bite is worth no more than the first (no kill stealing). A shark that is far too strong for a predator gets less (effort rule), so big sharks can't farm small predators.

## Where it lives
- `ReplicatedStorage.MegaBite.GameConfig`: `C.Combat`, `damage` on each predator type.
- `ServerScriptService.MB_Health` (new): one HP pool per player shark for predators AND the Red Trench; EXP with fractions kept.
- `MB_PredatorServer`: HP, `hit()`, HURT state (6), DEAD state (5), aggro, `PredBite` remote, respawn.
- `MB_FishServer`: fish HP, chunk bites, flee from biters, heal.
- `MB_PredatorClient`, `MB_FishClient`: outlines, tags, HP bars, damage numbers, bite on contact.
- `MB_PvPClient`: HP bar position; `MB_HUD`: toasts move below the bar.
- Backups in ServerStorage: `*_preCombat_13Nov`.

## Tested in Play (13 Nov)
- Minnow in the Open Sea: 3 shrimp eaten whole, then 2 bites on a Mackerel (HP 100% -> 56% -> 12%), +5 EXP per bite. Gold outlines on Mackerel and Tuna.
- Barracuda: Big Chomper hit for 108 (45% cap), three hits to be chomped. Reef Prowler fought: +53 EXP per bite (with the x2 pass).
- Hammerhead: Prowler bitten 4 times (312 damage each), it bolted, came back and bit for 115; Chomper joined in.
- No script errors in the console.

## Known limits
- The Studio screenshot tool does not draw "always on top" tags, so the name tags, fish HP bars and damage numbers were checked with a test copy, not in a real fight picture.
- EXP numbers above are with the owner's x2 EXP pass; a player without it gets half.
- Balance is a first pass. To tune after a real playtest: predator EXP (0.1 factor), recoil time, damage cap.
- Not built yet: late-game creatures for the Great White and Megalodon (next task).
