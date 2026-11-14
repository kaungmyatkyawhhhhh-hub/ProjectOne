# 2026-11-14 MEGA BITE - APEX HOUR, mutation cards, phase D

Owner: "do everything, dont ask me any questions" (build plan phases B leftovers, C, D, E). Nothing published. Studio saves up to v338.

## APEX HOUR (plan phase B)
- `ServerScriptService.MB_Events` APEX block: first at 240 s, then every 600 s, lasts 180 s, needs 2+ sharks (GameConfig.Events.Apex).
  The biggest shark in the Red Trench becomes the APEX (workspace ApexName/ApexEnd/ApexPos/ApexHP/ApexMax/ApexUid).
- Eating the APEX pays x2 bounty (MB_PvPServer, fires ApexDown). Surviving pays 25% (ApexSurvived); leaving the trench = ApexFled.
- Client `MB_Events`: the event pill becomes the APEX pill in the Trench, an APEX arrow, toasts in `Fx`.

## Mutation cards (plan phase C)
- 10 cards in `GameConfig.Cards`: Appetite, Hunter, Treasure, Quester, Tough, Heal, Fever, LongRush, Lucky, Glow (+ legendary 15%).
- Offer at half-way through an evolution. Owner rule (fossilize + evolve fast = card spam): only the CURRENT evolution can offer,
  never the top one, no catch-up for earlier ones, an old offer is dropped when you evolve, auto-open only in a calm moment,
  otherwise a purple "Card!" badge (LM 72,78). Server `MB_Cards`, client `MB_Cards`, remote `Remotes.Cards`.
- Tested 14 Nov: Leviathan (top) gets no offer; picking through the remote closes the picker.
- Icons: UIKit K.Icons Card* (vault UI/card_icons).

## Phase D
- Key hints (F / SHIFT / Q chips) on the ability buttons (MB_HUD keyChip).
- "DID YOU KNOW?" real fact per shark and fish in the Index (GameConfig.Facts).
- REVENGE: who ate you is tagged red for 60 s; eating them back pays half the eat reward (MB_PvPServer, client MB_Revenge).

## Phase E (files only, owner sets them when publishing)
- `UI/page_art/mb_thumb_hour1_hour100.png` (1920x1080) and `icon_raw.png` (1254 Megalodon icon, not cropped yet).
