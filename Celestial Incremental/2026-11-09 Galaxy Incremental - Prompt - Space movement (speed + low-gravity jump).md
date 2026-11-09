---
date: 2026-11-09
tags: [galaxy, prompt, claude-code, movement, feel]
---
# Galaxy Incremental: space movement (faster walk + floaty low-gravity jump) (owner, 9 Nov)

Owner: "i think the game needs like players need speed boost and jumppower boost cuz its in space".
Context: like ratio 5 up / 8 down (38%) after the broken mobile launch, so the game needs to feel good in the first minute. Related: [[2026-11-07 Galaxy Incremental - HOTFIX - players fall through their island]].

```text
GALAXY INCREMENTAL – SPACE MOVEMENT: FASTER WALK + FLOATY LOW-GRAVITY JUMP.
Do NOT playtest: the owner tests. Do NOT publish. Make the changes, review your code, report.

1. WALK SPEED: StarterPlayer.CharacterWalkSpeed 16 -> 24 for everyone, from the first second. Check that nothing else (tutorial, cinematics, EventController, windows) sets WalkSpeed back to 16; anything that freezes the player must restore 24 afterwards.

2. LOW-GRAVITY JUMP (space feel), PER CHARACTER, not global:
   - Do NOT change Workspace.Gravity (it would also change every unanchored part, VFX debris and drops).
   - Instead, on each character spawn, add a VectorForce on the HumanoidRootPart (RelativeTo World, ApplyAtCenterOfMass true) that cancels part of gravity: Force = (0, characterMass x (196.2 - 115), 0). Recompute the mass when the avatar loads (accessories change it).
   - Keep the default jump (JumpPower 50 / UseJumpPower), so the jump becomes about 11 studs high with a slow, floaty fall (about 1.8x the normal air time).
   - Make it feel like space: a soft whoosh + small stardust puff (the _alpha sparkle texture, LightEmission 0) on jump and a light dust ring on landing. Rate-limited, local only for others at half rate.
   - The character must still land on pads normally: the step-on pads' Touched logic is unchanged.

3. VOID SAFETY (higher jumps = more falls off islands):
   - If a character falls 40 studs below its island's floor (or below the lowest island - 40), teleport it back to its island's spawn point with a short fade + whoosh. No death, no lost progress.
   - Rails / invisible edge walls (CanCollide true, Transparency 1) around the parts of island edges where the main paths run, so a normal run never drops off by accident.
   - Do not break the streaming fix from the hotfix (RequestStreamAroundAsync before the teleport).

4. Put the values in GameConfig (Movement.WalkSpeed = 24, Movement.GravityCut = 115, Movement.VoidDepth = 40) so they can be tuned without code changes.

REPORT (short): files changed, the final values, where WalkSpeed was being reset (if anywhere), and how the void catch works.
```
