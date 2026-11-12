# Stomp Evolution - calm pass, kid cards, client-side breaking, city grid (13 Nov 2026, 01:36-02:30, autopilot)

Owner messages (01:36-01:39):
- "my legs sink in the ground when im star"
- "cards should be simple cuz its kid audience ... use the kid audience ui"
- "screen shaking is making me dizzy"
- "i feel like the game is overstimulating"
- "make breaking client sided"
- "on evolving ther is like a 2 second delay before the cutscene"
- "when the player first joins / after awakening, the bundle doesnt fully get in the player"
- "make it a city instead of a straight line"

Saved as v80 (not published).

## 1. Star legs sinking
- **Measured** at Star (scale 9.18): the feet were 7.5 studs under the ground; Starter at scale 1: 0.6.
- **Cause:** the R15 idle animation (also the player's pack idle) moves the root down about 0.8 per scale unit. The Humanoid's HipHeight (which matches the rig at rest) doesn't know that.
- **Fix:** new `StarterPlayerScripts.SE_FeetFix`. The client owns its body, so after every swap or growth (FormId / HipHeight change) it:
  - waits until the player stands still on the ground;
  - raycasts the ground and averages the gap to the lowest leg/foot corner over 8 samples;
  - lifts HipHeight by that gap.
- Star after the fix: -0.23 (just on the ground).
- **Lesson:** characters now use AnimationConstraint joints, not Motor6D. Measure feet against the ground in Play, don't compute them.

## 2. Armour not fully applied (join / after Awaken)
- **Cause:** `standardBody` only called ApplyDescription when the description "changed". After Star → Starter (boots only) it didn't change, so the Star torso and arms stayed on.
- **Fix:** ArmourKit now calls `ApplyDescriptionReset` every time. It also sets the animation slots to the defaults, so a pack idle can't lower the hips.
- Checked: going from Star back to Starter left no Star pieces.

## 3. Evolve cutscene delay
- **Cause:** the server fired `Evolved` only inside `applyBody`. When a growth job was already in flight (most stomps), the announce was swallowed and the cutscene waited for the body.
- **Fix:** `Evolved` now fires from the stomp handler the moment the form index goes up. The camera orbit starts at once, and the flash still waits for the new body.

## 4. Screen shake
`shake()` in StompClient is now a no-op: no camera shake anywhere.

## 5. Calm pass (overstimulation)
- StompFX `k()` uses 55% of the particles everywhere.
- Normal stomp: no white impact flash, 2 cubes (was 4).
- Ground Pound: no speed lines, no ripple ring, 7 cubes (was 14), a smaller flash.
- Prop crumble: no impact flash.
- Evolve burst: 12 cubes (was 22), a smaller flash.
- Aura particle rate 0.9 (was 1.7).
- Coins flying from a stomp: 1-4 (was 2-7); no flying stars.
- Buttons: no twinkles and no breathing; one slow sheen every 5-7 s on lime/gold only; the click burst has 8 pieces (was 16).
- The TALENTS square doesn't breathe any more.
- Music volume 0.2 (was 0.3).

## 6. Kid cards (TalentUI hand)
Replaces the Deepwoken-style parchment hand (backup `ServerStorage.TalentUI_preKidCards_13Nov`).
- A big "Pick a Power!" title (FredokaOne, white → gold).
- 3 bright cards in the family colour: a chunky slab, black outline, the family picture on a soft white circle, the name in big white letters, and ONE short line in kid words on a white strip ("Walk faster", "5 stomps in a row = x2!").
- A RARE / SUPER RARE sticker on rarer cards.
- No flips and no freeze/burn aces; MY BUILD and LATER underneath.
- Pick: the others shrink away, the picked card grows, "You got X!", then it flies to TALENTS.
- TODO: the family pictures are still the sepia medallion art. Make 4 bright kid icons with ChatGPT.

## 7. Client-side breaking
- **Server** (backup `StompServer_preClientBreak_13Nov`):
  - `brokenBy[plr][prop]` = when the prop is back for that player; `aliveFor(plr, m)` replaces the global "Alive".
  - Golden stays shared: whoever smashes it first takes it.
  - The stomper gets `props` + `back` times; everyone else only gets the stomp (dust/sound).
- **Client** (backup `StompClient_preClientBreak_13Nov`): `localBreak()`:
  - hides the parts locally and sets a local `Alive` = false;
  - drops a rubble pile (templates moved to ReplicatedStorage.StompEvolution.Rubble);
  - after `back` seconds the prop rises out of the ground, with the rebuild sparkle and sound.
- Checked: smashed a flower → hidden for me with rubble; the server shows 0 hidden props.

## 8. City instead of a straight road
- **Street grid** (`ToyTown.City`, same Road/Sidewalk/Curb/Dash style):
  - cross streets at x = 230, 420, 700, 930 (z -334..334);
  - avenues at z = ±300 (x -50..1270), plus the main road;
  - sidewalks and curbs are cut at every intersection.
- **Street dressing** (`Dressing.Streets`): lamps every 40, benches, hydrants, traffic lights at the intersections, and 10 clouds put back.
- **New props** follow the same districts as before:
  - x < 300: small things;
  - 300-680: houses + cars/buses;
  - 680-1000: shop rows;
  - x > 1000: towers.
  - Buildings face their street. Parked cars, buses and bikes are in the lanes, curb items on the sidewalks.
  - Nothing sits on the roads, the train line, the landmarks or the pads.
  - 399 new props (marked with the attribute `City`): about 690 in total.
- Play check: 60 fps in Studio, no errors.
- **Mistake:** the first dressing clean-up also removed the main road's lamps, hydrants, traffic lights, benches and 9 clouds. The new street dressing put lamps, benches, hydrants and traffic lights back on every street, including the main road. Undo did nothing.

## Next
- 4 bright family icons for the kid cards (ChatGPT).
- The interiors of the big blocks are mostly grass: add parks/playgrounds or more houses.
- Phone test by the owner.
