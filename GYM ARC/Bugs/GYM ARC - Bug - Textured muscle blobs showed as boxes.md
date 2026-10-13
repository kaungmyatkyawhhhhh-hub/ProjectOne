---
date: 2026-10-06
tags: [gymarc, bug]
status: wont-fix (engine limit)
---
# GYM ARC - Bug - Textured muscle blobs showed as boxes

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** With the old blob muscles, the skin-textured version showed as plain boxes to players.
- **Cause:** A mesh built by a script on the server (EditableMesh) does not get sent to players' games.
- **Fix:** Not fixable on the server. Textured blobs were switched off; later the whole muscle system moved to meshes built on each player's own game.
- **Commit:** 38f69d4
