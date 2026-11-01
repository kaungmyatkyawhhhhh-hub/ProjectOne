---
date: 2026-11-01
tags: [gymarc, bug, fixed]
status: fixed in Studio (not published)
---
# GYM ARC - Bug - Robloxian body not applied (asset timeouts)

Owner (1 Nov): "my character is not changed to the robloxian 2.0".

## Cause
During that playtest Roblox's servers were struggling (asset loads `HttpError: Timedout` for the five Robloxian 2.0 parts 27112025 / 27112039 / 27112052 / 27112056 / 27112068, plus DataStore 502s and HTTP 429s). `Humanoid:ApplyDescription` still returned OK, so BodyService thought the body was on and stopped; the player kept their own avatar body. Not caused by the storyline work.

## Fix (Server/BodyService `applyBody`)
- It only counts when the torso mesh really changed (or the avatar already wore that torso).
- On join: 2 quick tries, then up to 7 more in the background (about a minute, `ApplyDescriptionReset` so the same description isn't skipped). When one works, the frame, proportions and muscles are rebuilt (BodyVersion +1). The join never waits for the retries.
- Studio test switch: Workspace `TestBodyFail` = n makes the next n tries "succeed" without changing anything.

## Tested
With `TestBodyFail = 3`: the body went on at 5.6 s after join ("[BodyService] Robloxian body on ... (after a retry)"), all five parts Robloxian 2.0 meshes (1660648xxx), muscles rebuilt, no errors. A normal join (no fake failures) wasn't re-run: Studio got stuck starting the play-test.
