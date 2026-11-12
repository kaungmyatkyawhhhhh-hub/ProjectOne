# Stomp Evolution: every MEGA BITE (+ Galaxy) lesson, applied (12 Nov 2026, evening)

Owner (20:12): "learn from ALL of the mistakes from mega bite mistakes and use the knowledge to make this game better".
Read: `Roblox Playbook/Lessons - Galaxy to +1 SHRINK` (all sections), the MEGA BITE Home + 19 build notes (owner corrections, lessons).
Back to [[2026-11-12 Stomp Evolution - First playable slice v0 (systems)]].

## Built now (Studio, saved; not published)
| MEGA BITE / Galaxy mistake | What Stomp Evolution does now |
|---|---|
| HUD built piece by piece, 7 styles; plain text; "placeholder UI" (owner many times) | `ReplicatedStorage.StompEvolution.UIKit`: ONE palette (`K.Colors`), 3 families: PLATE counters, `K.Btn3D` (lip + own-colour outline + gloss + shadowed text), drawn icons (coin, up arrow, star; no emoji). Every text sits on a plate (HEIGHT, NEXT bar, coins, quest card, toasts, hint, pad signs, lock badges, tags). |
| Phone overlaps; text under 14 px; HUD under Roblox buttons | ScreenInsets = CoreUISafeInsets; small-phone size class (height < 450 → x0.8, text floor 14 px); quest card moves top-left on phones (out of the thumbstick zone); narrower toast lane on phones; STOMP button left of Roblox's jump button; hint above it. `SE_UIAudit` (Studio) checks overlaps + smallest text: PC CLEAN, 14 px. Geometry check for SE 667x375 / Android 800x360 / 14 Pro 852x393: clean. |
| First quest was a walk, not the core action | NEXT UP quest card (white card, gold sticker, lime bar, reward pill): 15-step chain, first = "Stomp 5 things to GROW"; counted on the server where it happens (never by watching an attribute). Reward coins fly into the counter. |
| Big evolve had no build-up; evolve sound missing on some paths | 2.5-3.5 s evolve cutscene: dark + letterbox, orbit camera, flash timed to the armour swap (waits for FormId), light burst + rings + sparkles, name card "YOU EVOLVED! STONE!" + FORM n / 8 pips (new pip pops last). The cutscene itself plays the Evolve sound. Controls off during it. Others get a small toast + 3D sound only. |
| Rewards just appeared; UI "no motion" | +MASS popup, coins fly into the coin counter, stars into HEIGHT; counters bump; numbers roll up; toasts punch in; quest card bumps. |
| Size tags in pixels covered the screen; no "who is bigger" | Height tags drawn per viewer, sized in studs, nearest 12, MaxDistance; badge by SHAPE: up arrow on coral = taller, down on lime = shorter, "=" on white = within 5%; drawn crown. |
| Crown flickered between players | Crown: checked every 2 s, needs 6 s strictly taller, changes at most every 20 s. |
| Lock badges / arrows at hand-typed spots | Lock badges ("LOCKED BE 6 m") on the prop's top, studs-sized, nearest 8 only; quest guide arrow adorned to the target (nearest prop of the quest's kind, or the nearest pad). |
| Studio tests wrote the real save (Galaxy) / Studio session lock wait (MEGA BITE) | Studio never saves unless `workspace.SE_StudioSave = true`; the `SE_Debug` hook marks the session no-save; UpdateAsync save. |
| Swapping a body mid-step | Root anchored during armour swap + rescale, then GettingUp (the character used to fall over). |
| Highlight cap (outlines missing) | Golden props capped at 12 Highlights. |
| Neon bloomed to white blobs | Pads: smooth saturated plate + thin neon rim (Transparency 0.3). |
| Dark lighting (Galaxy x2) | Ambient 120 / Outdoor 140, warm top light, mild colour correction, bloom 0.6, no depth of field. |
| Placeholder / Fish Audio sounds | 13 own code-made sounds (below), C-major pentatonic UI family (same key as MEGA BITE), mid-range body so stomps read on phone speakers. Uploaded to group 33151111, waited until Approved before Studio used them (failed fetch sticks), universe 10775970272 granted Use. |
| Streaming: client saw empty props | Center/Size attributes + Atomic streaming (v0). Void / out-of-town rescue on the server. |
| Kids waited for the first action | A welcome patch of 7 props (3 kinds) right in front of the spawn; spawn faces down the street; reach 8 studs. |

## Sounds v1 (`TITAN ARC/Audio/sfx_v1`, script `stomp_sfx_make.py` + `kit.py` from MEGA BITE)
| Sound | ID | Use |
|---|---|---|
| Stomp | 107950930870682 | every stomp (pitch drops as you grow) |
| GroundPound | 73652539577102 | every 15th stomp |
| CrashSmall | 111692367024345 | flowers, bins, mailboxes, bikes |
| CrashBig | 71596024671826 | cars and bigger |
| Coin | 127787196295450 | coin lands in the counter |
| Star | 79210169635704 | mass star lands, new form pip |
| Golden | 119076190483232 | golden prop |
| Upgrade | 76367347298858 | pad bought |
| Deny | 130617372213874 | not enough coins |
| Quest | 88850026682370 | quest done |
| Evolve | 104133985467401 | cutscene (hit at 1.05 s) |
| Crown | 127535480012206 | you take the crown |
| Toast | 106951237438237 | toast pop |

## Live-config bot run (Studio, best-choice bot, 2 min)
Brawler at once (the first golden landed as it started), Stone 9 s, Iron 29 s, Magma 70 s, 6.95 m at ~2 min; quests 2-4 chained inside 5 s.
That is about 2x faster than the impatient-kid sim plan (version H) for the middle forms. A bot has no walking or thinking time (kids ~1.3-1.5x slower), so re-tune after the owner's phone test, with the real kid sim.
Fixed from the run: the "IS MAXED" toast repeated on every pad touch (now once); the stomp hint stayed for players who never clicked (now leaves once you have broken something).

## Still open (from the same lessons)
1. **Music:** the rule is an upbeat licensed playlist (APM / Monstercat, 115-140 BPM). Picking by name in the store search is a guess; needs listening. `C.Music = {}` is wired (crossfade, 30 s load wait).
2. **HUD mockup approval:** Galaxy rule "design the whole HUD once, owner approves". This HUD is the proposal: owner to judge.
3. **Props are part-built blockouts:** the HIGH QUALITY model rule (reference study → sheet → Blender → owner approves) still has to run for the 9 prop kinds.
4. **Icon art:** coin / height / crown are drawn in code; the ChatGPT pipeline can replace them with real icon art.
5. **Real phone test** on the owner's phone (thumbstick reach, STOMP button, text).
6. **Impatient-kid sim on the live config** + a 2-player test with streaming.
