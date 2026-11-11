---
date: 2026-11-02
tags: [gymarc, bug, moderation, urgent]
status: fixed in Studio 2 Nov, waiting for publish ([[2026-11-02 GYM ARC Hotfix - Sexual Content suspensions (clothes always on)]])
---
# GYM ARC - players get "Roblox suspended you from this game for 1 minute: Sexual Content" (2 Nov)

Owner screenshot: Reason "Sexual Content", moderator note "your avatar broke the rules. Immediately change your avatar the next time you join this game". Owner: it happens to everyone; "when u look through glass, everyone shirt and pants disappear"; asked "is it cuz the muscle bodys dont have shirts on them".

## Cause (most likely)
- This is Roblox's automatic avatar check inside games: it looks at how your avatar LOOKS in the game. GYM ARC replaces everyone's body with big skin-coloured muscle meshes; if the tank top / shorts are missing or see-through, the character looks naked -> flagged as sexual content, for every player.
- The glass clue: Roblox does NOT draw transparent things behind Glass-material parts. If our shorts / tank top are transparent at all (Transparency > 0, LocalTransparencyModifier, see-through texture, decal), they vanish behind every gym window -> naked muscle bodies through glass.
- Also risky: shirtless choice (MINE / shirtless), skin-tone glute / crotch muscle shapes, NPCs / statues without clothes.
- Earlier warning: owner's account was hit once over a muscle-body image (30 Oct). Not confirmed by Roblox how the in-game check samples; fix every way a body can look nude.
Research: DevForum threads show automated "Sexual Content" actions are common in 2026 and appeals are often auto-denied, so prevention matters more than appeals.
