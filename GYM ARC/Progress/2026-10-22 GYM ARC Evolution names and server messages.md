---
date: 2026-10-22
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Evolution names and server messages (prompt 48)

Prompt: [[2026-10-23 GYM ARC Prompt - 48 Evolution names and server messages]]. Feature: [[GYM ARC - Personal Trainers]].

## 1) Evolution names are no longer hidden
- MY TRAINERS: the EVOLVE button reads "EVOLVE > IRON-BORN" (the stage name in its own color, 3 px dark stroke), "· LV x" when it's ready; at LIMITLESS "MAX STAGE" (disabled). The needs bar says "MAX STAGE" too.
- The EVOLUTIONS chart shows all 5 stages with their real names and backgrounds. The dark glitching "???" tile and "COMBINE 3 TO DISCOVER" are gone (`Shared/UI/TrainerTile` has no hidden mode now).
- No "first discovery" any more: the evolve moment always stamps "IRON-BORN!" etc. (fly together, flash, stamp, confetti stay).
- The seen-stages code is gone. Old saves keep their `discovered` list untouched (just unused).
- The roll reveal's duplicate line already said "2/3 to IRON-BORN" (27b).
- Trainers themselves still stay hidden until owned (silhouette; Secret and Eternal "???" on the odds grid).
- Small kit fix: `Theme.Uppercase` now leaves RichText tags alone, so a colored word in a button stays colored.

## 2) Server-wide messages: only the rarest rolls
- **Kept:** a Secret (The Shadow) or Eternal (Atlas) roll. Everyone else on the server gets a short gold banner under the top bar for ~4 s ("RONG ROLLED ATLAS!" / "ETERNAL TRAINER" in the rarity's color) and a small chime. Everyone gets a chat line in the rarity's color ("Rong rolled ATLAS! (Eternal)"). The roller sees their own reveal plus the chat line.
- **Removed:**
  - Legendary and Mythic roll messages (chat line + toast to everyone). `announce = "chat"` and `Trainers.AnnounceFrom` are gone from the config.
  - "X discovered COLOSSUS!" (evolution discovery, chat + toast to everyone) and its server code.
  - The Server Boost purchase toast to everyone ("Rong: 2x gains for 15 minutes"). Only the buyer is thanked now; everyone still sees the boost in their boosts row.
  - The posing show's "X won the Y division!" toast to everyone. Placed players still get their own reward popup; confetti at the stage stays.
- **Not found (nothing to remove):** alters, growth spurts and titles had no server-wide messages.
- **Left as they are (game events, not news about a player):** the alter flash for players standing nearby (a visual, no text), rush hour notices, the visiting legend NPC notices, the "server is updating" notice, crew messages (only to that crew) and high fives (only the other player). Tell me if any of these should go too.

## Tested (Studio, temporary save, solo)
- A BASE Coach Sam: "EVOLVE > IRON-BORN · LV 1" in orange; Atlas LIMITLESS: "MAX STAGE"; the chart with all real names; an evolve stamped "IRON-BORN!".
- A listener on the client counted server-wide trainer messages: a Common roll, an Epic roll and an evolve sent **nothing**; a forced Secret and Eternal roll sent one each.
- The banner as another player sees it (a faked roll from "Rong"), for Eternal and Secret. No errors.
- **Not tested with 2 real players** (Studio's 2-player test can't be started from here): please check once with a second player.

![[GYM ARC/Screenshots/prompt48/evolve_iron_born.jpg]]
![[GYM ARC/Screenshots/prompt48/limitless_max_stage.jpg]]
![[GYM ARC/Screenshots/prompt48/evolutions_chart_names.jpg]]
![[GYM ARC/Screenshots/prompt48/evolve_moment_no_discovered.jpg]]
![[GYM ARC/Screenshots/prompt48/banner_eternal.jpg]]
![[GYM ARC/Screenshots/prompt48/banner_secret.jpg]]

## Note
- The banner shows the trainer's real name ("ROLLED ATLAS!"), as in your example, even to players who don't own him yet. Before, a hidden trainer's name was "???" for them.
