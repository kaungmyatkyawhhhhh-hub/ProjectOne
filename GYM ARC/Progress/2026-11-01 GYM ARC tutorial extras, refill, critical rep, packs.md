---
date: 2026-11-01
tags: [gymarc, progress, tutorial, monetization]
---
# GYM ARC - tutorial extras, stamina refill, CRITICAL rep, starter/premium packs (1 Nov)

Owner request (1 Nov): invite dialogue in the tutorial, stamina-0 treadmill hint + 5 R$ refill, CRITICAL on the REP button instead of "big rep" text, shake offer only after using items, end-of-tutorial "this is only the beginning" with the 8'0" mass monster, Starter Pack 30 min then Premium, WORTH 199 / WORTH 599.

## Done
- **Dev product** "Instant Stamina Refill", 5 R$, id 3726399101 (Creator Hub). Config.Monetization key `StaminaRefill`, `store = false`. MonetizationService: stamina to max (`PlayerData.SetStamina`, clears StaminaRecovering), fires PlayerEvent "StaminaRefilled".
- **TutorialExtrasClient** (new, StarterPlayerScripts), only for players in the tutorial this session:
  - INVITE card 8 s into step 7 ("Goal"): "+10% EXP per friend in your server" (Social.Friends.GainsPer), INVITE (UIBus.InviteFriends) / LATER.
  - OUT OF STAMINA card the first time StaminaRecovering turns on: TAKE ME THERE (GuidePath.Teleport) / I'LL WALK; gold path + marker "TREADMILL" (owner "StaminaTip"; the tutorial's path comes back after).
  - 5 s on a Treadmill/ProTreadmill with stamina not full: INSTANT STAMINA REFILL card (animated stamina bar, R$ 5, X). Once per session.
  - Tutorial end: PlayerAction "ShowPotential" -> MirrorService builds your avatar at 8'0" (TopHeightInches) with every muscle at MonsterG, into your PlayerGui; client places it 12 studs ahead facing you (closer if a wall), in Workspace.HallStatues (MuscleClient draws muscles), letterbox camera over your shoulder, "THIS IS ONLY THE BEGINNING" / "Your full potential: 8'0" MASS MONSTER" / LET'S GO (auto 14 s). Other screens hidden during it, restored after.
  - Studio hooks: Workspace attrs TestInviteCard / TestStaminaTip / TestRefillCard / TestPotential.
- **MachineClient**: CRITICAL! label + pulsing gold stroke on the REP button when the next rep is a big rep; the "Big rep +X" screen text replaced by a gold gain popup.
- **OfferClient**: shake bundle offer only after an item is used (35% chance, 20 min gap, max 2/session, never in tutorial).
- **Starter Pack**: 30 min window (WindowHours 0.5), "WORTH 199 R$" for 29 R$; after the window (not bought) the Premium Pack opens, "WORTH 599 R$" for 199 R$. Value check: starter contents ~258 R$, premium ~845 R$ at store prices, so the WORTH claims are honest.

## Tested (Studio)
Potential cinematic (statue faces you, HUD hidden, restored), all three cards, treadmill path/marker, no console errors. Full new-player run not done in Studio (would overwrite the owner's save); test with the alt account after publishing.

## Owner to-do
- Publish. Test the tutorial with the alt account (invite card, run out of stamina, treadmill, end screen).
- StreamingTargetRadius 160; check the Performance dashboard.
