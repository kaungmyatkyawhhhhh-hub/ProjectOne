---
date: 2026-11-05
tags: [galaxy, progress, phase-1, social, boards, music]
status: built and tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - social basics, board brightness, music playlist (5 Nov, Claude Code)

Three owner prompts, in order: Phase 1's last step "SOCIAL BASICS", then "ISLAND BOARDS LOOK FADED", then "MUSIC". Place "Galaxy Incremental" (111654682859982). GYM ARC was not touched.
Checklist rows: **#290 #392 #394 #395** (social), **#233 #234 #235 #237** (music), new **#485** (boards). Statuses updated in [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]].
- Your prompt named the friend boost "#392, #394". In the checklist, #392 is the Supernova chat line, #394 is friends and #395 is the group. I used the checklist numbers.
- Screens: `Progress\screens\2026-11-05-social-boards-music\` 01-14.

## 1. Social basics
**Friend + group boost (#394 #395)**
- +10% stardust for each friend in your server, max 3 (+30%), and +10% in the P&L Studios XP group (947215423).
- Both ADD to the other boosts (#69). Tested with the x2 pass on: x2.0 → friends 2 = x2.2 → 5 friends (capped at 3) = x2.3 → + group = x2.4.
- The group is checked once when you join and cached. Friends are counted again when anyone joins or leaves; each pair is asked once per server.
- **Chips** under the potions (same card look):
  - "FRIENDS +20%" only shows when a friend is in the server.
  - "GROUP +10%", or "JOIN GROUP FOR +10%" when you're not in the group.
- **One small addition:** tapping "JOIN GROUP FOR +10%" opens Roblox's join-group prompt. After joining, the server checks again (at most every 10 s). Say if you don't want this.
- Studio switches: Workspace `TestFriends = n` and `TestGroup = true/false`.

**Server message on Supernova (#392)**
- Everyone in the server gets a system chat line, "<name> went SUPERNOVA (12)!", in the player's rank colour.
- Max 1 per player per 30 s. Tested: a 2nd Supernova 15 s later sent no line.
- The FIRST Supernova and a CELESTIAL Forge roll also show a 3 s banner at the top of everyone's screen (screen 02). The Celestial roll used to be a toast.
- Plugged into the existing global hook (EconEvent FireAllClients, same as ForgeGlobal).
- Mythic Forge rolls don't go to chat (your prompt didn't ask for that), so #392 stays PARTLY.

**Rank aura (#290)**
- One particle emitter per player, using our own fx_sparkle texture, tinted with the Cosmic Level band colour.
  - Tiers 1-2 (SPARK, FLARE): no aura.
  - Tiers 3-5 (BLAZE, NOVA, SUPERGIANT): a faint aura, sparkles floating around the body (screen 03).
  - Tiers 6-7 (HYPERGIANT, QUASAR): brighter, and the emitter orbits the body, so the sparkles leave a ring of stars (screens 04, 05).
- The aura turns off past 60 studs.
  - Low graphics (quality 1-3): 40% of the sparkles and no orbit.
  - Reduced Motion: half the sparkles and no orbit.
- Everyone sees everyone's aura.
- **First try was invisible:** at tier 3 the sparkles were born inside the body. They are now thrown about 2 studs out.

**Test results**
- **2-player local server: NOT run.** The PC had 0.4 GB of free memory and 3 extra Studio windows would likely crash it.
  - Instead: the switches above, plus the server firing the real event to the client.
  - Studio test players can't be friends, so the real IsFriendsWith path is untested. Please check it with a friend in the 8 Nov test.
- **Chat line:** confirmed through TextChatService (MessageReceived). Studio screenshots don't show the chat window.
- **8 players' auras:** 8 rigs, all at the top tier: 14.9 fps vs 15.0 without auras (screen 06).
  - That's the Studio PC under memory pressure, not a phone. The aura costs nothing measurable there, but no real phone was tested.
- **Phone frame:** the chips and the banner fit (screen 14).
- **Side effect:** your Studio save went from 11 to 16 Supernovas (test Supernovas; Studio keys only, not real saves).

## 2. Island boards looked faded (#485)
- **Cause** (as you found): the screens' SurfaceGuis had Brightness 1 with LightInfluence 0, so the haze, the colour grade and bloom washed them out.
- **Brightness tested in Play:** 1.5 / 1.8 / 2.2 (screens 09-11). **1.8 picked.**
  - At 1.8 the whites and the green / purple buttons look like the 2D window (screen 08), and the dark rows stay dark.
  - At 2.2 the dark rows turn purple, which washes out the contrast again.
- **Where it applies:** `MapConfig.Boards.Brightness = 1.8`
  - all 4 island boards and their big titles
  - every map sign made by MapBuilder.surface
  - the 10 signs already in the place (Star Surge, Forge, Black Hole gate, leaderboard, Ignition / arch signs), set in Edit
  - Leaderboard after: screen 13, no bloom.
- **In front of the screens:** nothing transparent. Only the neon edge tubes sit in front of the screen plane, and they're outside the screen area. They're now CanQuery off anyway, so they never catch a click.
- **Opaque fills:** the TREE board's tiles were 0.05 transparent (locked 0.4).
  - On the 3D board they're now fully opaque; a locked tile gets a darker fill instead.
  - The 2D TREE window is unchanged.
  - Screen 12: TREE after.
- **Not checked:**
  - Day/night: the sky is fixed, so there is no day/night to check.
  - Phone: boards are 3D, so the phone frame doesn't change them.
- Before / after: screen 07 (1.0) vs screen 10 (1.8).

## 3. Music playlist (#233-#235 #237)
- **The old loop** (APM "Ethereal Drone" 1837463526) is gone.
- **Playlist (all APM):** Final Frontier 1844631856, Into the Sun (b) 1840016117, Go! 1840300465, Future Plans (A) 1840772819, Full Contact (a) 1841008234. All 5 load (not moderated).
- **Rotation:**
  - Shuffled each session; each track plays once, then a new shuffle.
  - Never the same track twice in a row, also across the reshuffle.
  - 2 s crossfade.
  - The next track loads while the current one plays.
- **Trims:**
  - Intros are all under 0.5 s, so no intro trims.
  - Each track's silent tail (3-5 s) is cut with PlaybackRegion.
- **Loudness**, measured in Studio (average PlaybackLoudness over 7 points per track) and matched to ~130:

  | Track | Measured | Volume |
  |---|---|---|
  | Final Frontier | 116 | x1.1 |
  | Into the Sun (b) | 139 | x0.95 |
  | Go! | 144 | x0.9 |
  | Future Plans (A) | 187 | x0.7 |
  | Full Contact (a) | 326 | x0.4 |

- **Music bus 0.4** (the old loop was 0.35). The MUSIC slider (saved) sits on top as before.
- **Supernova:** the music fades to silence in 0.3 s and the track pauses. After the Supernova it resumes the same track at the same second and fades back in over ~1.5 s (same timings as before).
- **Big windows:** the music drops to half while UPGRADES, the TREE, STORE, FORGE, GALAXY or the GUIDE BOOK is open.
  - This wasn't actually built before ("as before" in the prompt), so it's new.
  - SETTINGS doesn't duck, so you hear the slider while you drag it.
- **A track that won't load** (moderated or gone) is skipped, logged ("[GalaxyMusic] skipped ..."), and left out of later shuffles. The playlist keeps going.
- **Tests (Studio):**
  - Join: track 1 ("Go!") plays and the next is preloaded.
  - Skip to the end (`TestMusicSkip`): a 2 s crossfade at the trimmed end.
  - 8 tracks in a row: Go! → Future Plans → Into the Sun → Full Contact → Final Frontier | new shuffle: Into the Sun → Go! → Final Frontier → Full Contact. No repeats.
  - Supernova mid-track: Full Contact paused at 72.8 s and resumed at 72.8 s.
  - MUSIC slider 0% = silent, 100% = full; put back to 60% (SFX back to 80% after I bumped it).
- **Not tested on a real phone.** Music doesn't depend on the screen size.
- Please listen and say if any track is too loud or too quiet. Loudness was matched by numbers, not by ear.

## Output
- No errors in the Output after the final Play.
- All 35 scripts: vault = Studio.
- Test switches cleared.

## For you
1. **File > Save** in Studio. Nothing was published.
2. In the 8 Nov friends test, check the real friend boost (two friends in one server) and the chat line on two screens.
3. Listen to the playlist for loudness.
