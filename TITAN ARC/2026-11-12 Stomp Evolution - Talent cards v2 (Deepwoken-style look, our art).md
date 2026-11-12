# Stomp Evolution: talent cards v2 - Deepwoken-style look, our own art (12 Nov 2026, 21:48-22:40)

Owner (21:48): "make it 1:1 deepwoken style but make it our style too. go research https://builtbybit.com/resources/roblox/graphics-ui/".
Back to [[2026-11-12 Stomp Evolution - Talent cards, builds and resets (Deepwoken-style)]].

## Research
**BuiltByBit Roblox graphics-UI listing (12 Nov):** the store is dominated by stud-style / cartoony simulator packs (shop, rewards, rebirth, upgrades, spin wheels), animated toast stacks and HUDs, modular editable frame kits (13-40+ elements) and colour-coded rarity tiers. No card/talent/RPG kits on the page. Takeaway: the kid market's UI language is chunky, colourful and animated; a dark serious RPG screen would stand out but must stay readable.
**Deepwoken power-up screen (watched: YouTube "How to pick Talents/Cards in DeepWoken", Hkplayzzs, frames at 0-10 s):**
- no window: the cards float in ONE row across the middle of the screen over the dimmed world;
- an italic serif flavour line above the row ("...comes from many sources...");
- cards arrive FACE DOWN (ornate patterned back) and flip to parchment faces;
- face: aged parchment, thin dark double-line border with corner studs, title in a banner at the top (serif), an ink icon on a round plaque in a square frame, a small category line, the effect text in serif, a grey requirement line under each card;
- a "stat INCREASED" banner with flourishes after a pick; freeze/burn are "Aces" used on cards (Wiki: freeze keeps a card until picked; burn removes it forever; burning the whole hand redeals).
Rule: copy the LAYOUT, FLOW and FEEL, never their art, ornaments, fonts' exact look, card names or text.

## What was made
- **ChatGPT sheet** (one try, chat "Create Game Asset Sheet"): our own ornament = giant footprints + cracked ground + four-point stars (asked explicitly: NOT celtic knotwork, not from any game). Card back, empty sepia front, gold-foil front (Advanced), and 6 ink medallions (boot slam = QUAKE, coins = GREED, winged boot = STRIDE, sprouting arrow = GROWTH, snowflake = FREEZE, flame = BURN).
- Processed in the browser (no Downloads access): magenta key with soft global pass + un-mix, cut by coverage runs (3 cards + 6 icons cleanly separated), 1 px alpha erosion + magenta-fringe pull, previewed on navy, sent by postMessage to a Roblox tab and uploaded (group 33151111, all Approved):
  | Piece | ID |
  |---|---|
  | Card back | 124294156214734 |
  | Card front | 135412578741169 |
  | Card front gold | 94410676338113 |
  | Quake / Greed / Stride / Growth | 115228780513435 / 74903840536819 / 106125081753067 / 136813707198423 |
  | Freeze / Burn | 106593517356359 / 79976697001779 |
- **Hand screen rebuilt** (`TalentUI` openHand): world dims, our flavour lines ("Your weight is starting to matter..."), POWER line, cards deal face down and flip one by one (sound per rarity), hover lifts, pick = glow + rise + "— QUAKE GROWS —" banner + flies into the TALENTS button; FREEZE / BURN are ace medallions beside the row (tap ace, tap card); burn scorches the card bottom-up and it falls away; frozen cards show frost.
- **Our style kept:** the purple TALENTS button and kit buttons (MY BUILD / LATER), family colours on the category line, our sounds, kid-readable sizes (serif Merriweather, text >= 13-14 px).
- Config: `C.CardArt`, `C.CardFlavour`. Place saved v47.

## Next
- Build window + shrine panels in the same parchment style.
- Burn embers as real particles on a 3D layer if wanted.
