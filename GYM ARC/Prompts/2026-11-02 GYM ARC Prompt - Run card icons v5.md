---
date: 2026-11-02
tags: [gymarc, prompt, ui, art]
status: done 2 Nov (Studio, not published)
---
# Prompt: swap the Run Card icons to the new set (v5)

Owner (2 Nov):

> GYM ARC: SWAP THE RUN CARD ICONS TO THE NEW SET (v5). Never touch Galaxy.
> New icons: GYM ARC\Assets\icons_v5_runcards\ (preview _preview.png). Each PNG already includes the dial background and its colour glow, like the old ones.
> I uploaded them to Myanmar Builders Club. Ids (fill in, or find the decals I dropped in Workspace):
> - gymarc_icon_star -> All Muscles cards
> - gymarc_icon_coins -> Coins Per Rep / coin cards
> - gymarc_icon_bicep -> Arms
> - gymarc_icon_shoulders -> Shoulders
> - gymarc_icon_chest -> Chest
> - gymarc_icon_back -> Back
> - gymarc_icon_abs -> Abs / Core
> - gymarc_icon_legs -> Legs
> 1) Find every place the old 8 icons are used (Run Cards config, card hand, My Build / Legacy list, tracker, odds window, anywhere else the same ids appear): grep the old asset ids, then replace them with the new ids in ONE config table (no hard-coded ids in UI scripts).
> 2) If a card type has no matching icon, tell me which one; don't reuse a wrong icon.
> 3) Check group ownership: every new id must load in Play (no grey squares). If one is grey, tell me which.
> 4) Screenshots: the Choose a Card hand (common + rare), My Build, the tracker, on PC and phone. Progress note in GYM ARC\Progress\.

Result: [[2026-11-02 GYM ARC Run card icons v5]].
