---
date: 2026-10-20
tags: [gymarc, prompt]
status: done
---
# 18 Posing show every 5 minutes

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Build the posing show: a server-wide competition every 5 minutes. Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" (sections Core loop, Posing shows and judging) first. Needs the fixed poses from prompt 10. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first. Kids' game: losing must still feel OK.

1) SCHEDULE
- One show every 5 minutes per server (config: ShowInterval = 300).
- A small HUD timer for everyone who has unlocked shows (Growth Spurt 1+): "POSING SHOW 2:30". At 0:30 left it pulses gold and shows a JOIN button that walks you to the stage (or teleports you if you're far away or in another gym).
- Players who skip it are never interrupted. Training continues normally.

2) STAGE AND JOINING
- The posing stage is at the Beach Gym: a raised stage, a backdrop, spotlights, a crowd area, and a 3-step podium (1st/2nd/3rd).
- Join by stepping into the glowing stage zone before the timer ends (or with the JOIN button). Max 8 contestants per division in one show.
- Divisions by height: Bantam (under 5'0"), Middle (5'0"-6'0"), Heavy (over 6'0"). After 7'0", divisions are by alter tier (code it now; alters come later, so everyone at 7'0" is "Open" until then).
- Run the divisions one after another in the same show, smallest first. Need at least 1 contestant (solo players still get judged and rewarded). Fill empty spots with 2-3 NPC competitors, scaled to that division, so it never feels empty.

3) THE SHOW (under 60 seconds per division)
- Contestants line up on stage. The camera goes to a stage view for contestants, and other players can watch.
- Judges call each pose: side chest, front double biceps, back double biceps, abs and thighs (about 5 s each). All contestants hit the pose together. Crowd cheers, camera flashes, spotlights.
- Use the same pose system as the emotes/poses (prompt 10).

4) JUDGING (server-side, all numbers in one config module)
- Score out of 100: muscle size 60%, balance across the 6 groups 25%, height + alter ("stage presence") 15%.
- Score relative to the division (size compared to the division's best), so small players can win their division.
- NO purchase, aura, pass or boost changes the score.
- Show each contestant's score with a judge panel: "Size 52 / Balance 21 / Presence 11 = 84".

5) RESULTS AND REWARDS
- Top 3 walk onto the podium with confetti and a fanfare. Names are shown to the whole server.
- Rewards scale with the show level and place: 1st big coins + 1 trophy, 2nd/3rd smaller coins, everyone who competed gets a participation reward (coins + "Good effort!").
- Save each player's stats: shows entered, wins, trophies, best score. Show them in the profile/stats.
- Titles: first show entered, first win, 10 wins, 50 wins.
- Show ladder (only the label, prizes and backdrop change for now): Local Show (Spurt 1), Regional (Spurt 2), National (Spurt 4), Pro Card Qualifier (Spurt 5), Universe Championship (7'0"). Players compete in the highest show they've unlocked.

6) PHONES AND PERFORMANCE
- The JOIN button and results fit 667x375. Big tap targets.
- Stage effects are light (few particles, no extra shadows). NPC competitors use the low-poly stage meshes.

7) ANALYTICS
- Log: show timer seen, join tapped, competed, placed (1/2/3/other).

Test with 1 player plus NPCs, and with 2 players in different divisions. Phone screenshot of the timer and the results. Short progress note in the vault.
```
