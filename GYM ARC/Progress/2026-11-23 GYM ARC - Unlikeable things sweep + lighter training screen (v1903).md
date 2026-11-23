# GYM ARC - Unlikeable things sweep + lighter training screen (v1903, 23 Nov 2026)

Owner: "check for any unlikeable things", then (screenshot of the beach push-ups) "the ui covers so much of the screen".
Method: 3 new-player runs on a phone (844x390, touch) to Growth Spurt 2, with screenshots plus a log of every pop-up showing and hiding.
Saved as **v1903, NOT published**. 0 errors in the final run; chapter 1 still takes 2.3 min.

## Training screen: before / after
Before, the weight card covered the middle-right of the screen, with the AUTO REP (PASS) button under it and toasts on top of it.
- **Compact weight card** (`MachineHud.Compact = true`):
  - The EXP numbers line ("Mid Chest 143K / 168K EXP") is gone; the gold NEXT bar already shows it.
  - The "Tier 6/12" line is gone unless it carries the plate row or BEST WEIGHT.
  - The card is now ~92 px instead of ~160 px and sits in the right column above PUMP and REP. The middle of the screen is clear.
  - The "Needs ... PLATES" line still shows when it matters.
- **AUTO REP (PASS) button:** hidden during the tutorial and chapter 1. MachineClient now re-checks it when the tutorial state changes; it was decided only once at startup.
- **Empty plate row** (6 dim plates): hidden in the tutorial when no plates are owned.
- **Toasts while lifting:** the lane shifts left (`Notify.TrainingShift = -120`), so NEW WEIGHT UNLOCKED and Muscle of the Day no longer sit on the weight card.
- **Chapter 1 counts as tutorial for noisy toasts** (new weight, LVL, milestones, playtime).

## Other unlikeable things fixed
1. **Starter Pack card flickered** in and out for half a second on every GO TO between machines.
   - It now waits 3 s of free screen and is never shown in chapter 1.
   - When lifting, it must be 40 px clear of every HUD button. It had sat 10 px under REP, the button kids tap nonstop.
2. **Skate button blinked** between machines: it now waits 2.5 s after training.
3. **Daily reward window flashed for half a second** between tutorial machines, then closed, so a new player never saw it.
   - It now waits for the end of chapter 1 and 3 s off a machine.
4. **Invite-a-friend card stayed through Growth Spurt 1** and the Benny scenes: it now hides at the first grow.
5. **Duplicate Dex line:** "Great chest! Now your CORE." then "Great chest! Next: CORE..." Now it's one line.
6. **Growth Spurt shot:** an NPC beside you stayed as a big see-through ghost over a third of the shot. Nearby characters are now fully hidden for the moment (GrowthFX).
7. After Benny is beaten, the tutorial hides its path and GO button until his scene is over (TutorialClient).

## Checked, not a problem
- The dark intro frame was the 0.8 s fade-in from black.
- "Beat BENNY" after the win was my test reading a hidden label.

## Not fixed (for the owner / later)
- Off a machine the screen is still busy: 9 left tiles (3 of them LOCKED, red "!" badges) and 3 cards on the right. Idea: hide locked tiles until they unlock.
- The Starter Pack still shows "Worth R$199 / ONLY R$29" with a timer (fair-money update).
- The "Out of stamina! Jog on a TREADMILL" Dex box covers the body with Tap to continue (owner asked for it in the tutorial, 1 Nov).
- The skate button still blinks once (0.5 s) on the beach arrival → Coral teleport.
- Judge final layout on a real phone: the Studio phone view scales the UI but not the 3D view.
