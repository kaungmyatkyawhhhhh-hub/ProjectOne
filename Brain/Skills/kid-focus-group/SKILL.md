---
name: "kid-focus-group"
description: "Use when deciding what goes into a Roblox game update or new game: ChatGPT role-plays groups of kids, Claude pitches the live game and fixes objections until all vote for it."
---

# Kid focus group (ChatGPT)

Owner's words (9 Nov 2026): "u guys are multiple group of kids arguing over which roblox game to play. find the objections they have to yours and improve the game until everyone agrees to play ur game".

Use when: deciding what goes in an update or a new game, "would kids pick our game over X?", before ads or a big pitch.

Vault: method note `Brain/Methods/Kid focus group (ChatGPT).md`; worked example `Celestial Incremental/2026-11-09 Galaxy Incremental - Kid focus group + Prompt - next update (creatures, crew heists, jetpack, phone).md`. Read the vault Brain (`Brain/00 BRAIN.md`) and the game's notes first.

## 1. Read the LIVE game first
- Open the game in Roblox Studio (MCP). List the scripts and grep for the features you plan to pitch (e.g. steal, crew, trade, jetpack, mutation, graphics).
- Write down what's actually built vs only planned. Pitch only from this.

## 2. Set up the focus group (new ChatGPT chat, Claude in Chrome)
- Open a NEW chat on chatgpt.com in the user's Chrome (load the chrome-browser skill first; work in a new tab).
- Send ONE paragraph (Enter sends; no line breaks, or use Shift+Enter) setting up 3 groups of kids with names, ages and the real games they play:
  - Grinders (11-12): Pet Simulator 99, Grow a Garden, number-go-up games
  - Chaos squad (9-10): Steal a Brainrot, 99 Nights in the Forest, Dead Rails, trolling friends
  - Mobile kids (8-9): Brookhaven, easy obbies, cheap phones, bored in 10 s
- Rules for ChatGPT: stay in character, short slangy brutally honest kids, argue with each other, ONE vote each, hard to convince, never agree to be nice. End every reply with a scoreboard: each kid, their vote, their #1 blocker.
- Pitch the game exactly as it is live.

## 3. Rounds
- Read each reply with a JS helper that splits the page text on "ChatGPT said:" and checks for the stop button (busy); read long replies in 900-character slices.
- Each round, answer every kid's #1 blocker with ONE concrete change: real numbers, odds, timings, how it works on a phone. No vague promises.
- Be honest about live vs planned. If votes crash when the kids learn something isn't built, that IS the finding. Re-frame: "the next update can only hold N features", list candidates A-H, and let the kids pick and argue.
- To win the last holdout, prefer fusing their want into an already-picked feature over adding a new one.
- Stop at all-yes (write down each kid's condition: these are the acceptance tests) or when it stalls.

## 4. Deliver (save to the vault, the owner's "brain")
- Game folder note: the kids table, the rounds table (votes + what was pitched + what they said), each kid's condition, the lessons, a live-vs-missing audit, WHEN it ships (never disturb an update already built and in testing), and a copy-paste Claude Code prompt with every change as config values, a build order (riskiest last, with a fallback), server-side checks, analytics events, and checks before handing back (impatient-kid-sim re-run, quality-nerd check, Launch gate).
- Add a "Used on / Learned" line to the method note.
- Don't build or publish unless asked (the owner lets Claude Code build and tests it himself).

## Lessons so far
- Kids judge what they can play TONIGHT: votes went 5 -> 0 when they learned features weren't live. Never advertise unbuilt features.
- Fewer working features beat many promised ones.
- One fused feature (stealing + crews + a multiplier) wins several kid types at once.
- The cheap-phone kid vetoes everything: performance is a feature.
- It's role-play: use it to find objections, then confirm with real data (funnel, playtime, D1) after the update.