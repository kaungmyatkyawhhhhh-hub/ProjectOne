---
tags: [gym-arc, bugs, qa]
date: 2026-11-26
build: v1914 (Studio, unsaved fixes)
---
# GYM ARC: bug hunt loop, 26 Nov (01:00 MMT)

Owner: "try to find any bugs rn. if u find any, fix them, rerun test ... loop it until there is 0 bugs".
Method: 4 Play runs in Studio as a fresh player (FreshPlayer, temporary data), error/warning logs collected on server AND client, the tutorial run through to Benny and the beach, every menu window opened, 17 zones visited by teleport, admin jumps (`ServerStorage.Admin`: spurts 6, alter 5, plates diamond, genetics S, Atlas LIMITLESS, 50M EXP) to reach late-game states. Screenshots checked by eye.

## Bugs found and fixed (all in Studio, NOT saved or published)
| # | Bug | Cause | Fix | Re-test |
|---|---|---|---|---|
| 1 | Your trainer (Coach Lou) stood between the camera and you on the Flat Bench and never faded | `TrainerCameraFade` only tested the line camera→HEAD; lying on a bench, that line passed 0.3 studs beside him while he covered the body | also test camera→root and the point between head and root; any hit = fade | trainer fades (run 3, 4) |
| 2 | During the Benny arm-wrestle your "Rong" + "Crew Member" tags floated in mid-air beside the table | `StoryClient` hides your real body (it waits where you stood) with LocalTransparencyModifier, which doesn't hide BillboardGuis | the hide loop also switches off the body's BillboardGuis, `endMatch` switches them back on (same pattern as MenuClient's hideCharacter) | no floating tags, tags back after the match (run 3) |
| 3 | A stage-5 (LIMITLESS) trainer, 7.5 studs wide, stood INSIDE you at the machine | `TrainerFollowClient.machineSpot` picked hype spots 3.4 studs from the lifter whatever the trainer's size | spots must be ≥ trainer half-width + 1.2 studs away; the fallback ring and the normal follow spot grow with his width | trainer 6.5 studs away, beside you (run 4) |

## Checked, not bugs
- "REP x0": the number is the reps in this set (MachineClient line 2423), 0 at the start of a set.
- Title tag hidden on a machine: by design (OwnTagClient / OverheadTitleClient).
- 17 ConfigService "value not found" warnings: Studio has no published experience config; the code uses defaults.
- Tool artefact: Studio's execute_luau resets the camera type it saw, so a stuck Scriptable camera seen in run 1 came from the test tool, not the game.

## Left as harmless warnings (no player effect)
- `[StaminaService] No ShakeMachine in Workspace`: there's no shake machine in the map any more (the coach booth's Shaker is a prop); shakes come from quests, the hotbar and the store.
- `[TownService] Missing PosePrompt in Workspace.Town`: the old posing stage was replaced by THE RUNWAY; POSES opens from the menu.
- Empty `Workspace.TrianglePluginDebris` model (0 parts) left by a plugin.

## Final run
0 errors on server and client through: intro → tutorial → Growth Spurt → Benny match → beach → Coral scene → beach machines, every menu window, all zones, late-game admin states.

## Design issues seen (not bugs; go in the tutorial redesign)
- The tutorial plays itself: auto pump (owner, 3 Nov), GO TRAIN presses itself, Benny is won by auto-push. A kid mostly watches.
- Coral / Benny stand behind the player's own body when their scene starts.
- Coach Dex's dialog covers the player's head and title.
