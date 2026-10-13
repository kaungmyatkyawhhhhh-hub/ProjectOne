---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Soft Shutdown

Back to [[00 GYM ARC Home|GYM ARC Home]].

When an update closes the live servers, players are moved through a holding server and back into the new version instead of being kicked.

## How it works
- **Trigger:** Roblox closes a live server after a publish (Creator Hub > Servers > "Shut down all servers" or "Migrate to latest update").
- **Players see** a small note ("The gym is updating..."), get teleported together into one reserved holding server, and after about 6 s go back to a fresh public server on the new version.
- **Saving:** works as before (on close and when leaving by teleport).
- **Holding server:** runs only this service, never loads data or takes a save lock. Its loading screen says "Updating the gym / Taking you to the new version. Your progress is saved."
- **Retries:** teleports retry up to 4 times.
- Private server players come back to a public server. Off in Studio.

## Where it lives
- `Server/ShutdownService`; `Main` starts only this service in a holding server
- Studio hook `SoftShutdown` (Workspace attribute) shows the note and holding screen

## Known issues
- The teleports themselves only work in a live game: test after publishing (join, then "Migrate to latest update").

## Related
[[GYM ARC - Player Data and Saving]], [[GYM ARC - Loading Screen and Menu]]
