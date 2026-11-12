# Stomp Evolution - Feel pass v1 (music, sound set v2, UI motion, VFX kit) — 13 Nov 2026, 00:07-01:30 (autopilot)

Owner (00:07): "pick music for me like what u think the game audience will play and also make the sfx and uis better and more interactive and LOTS AND LOTS OF VFX like the shark game".
Read first: K06 (sound, UI motion, VFX rules), Lessons (hype music rule, group-audio universe grant), MEGA BITE VFX + UI sound notes.

## Music (picked by MEASURING the audio, not by name)
- Candidates from the Creator Store (APM / licensed partners). The browser fetched each track's audio and measured tempo (onset autocorrelation), key (Krumhansl major/minor), brightness, loudness, and whether the energy stays up (no long quiet parts).
- Rule used (K06 + Lessons 7 Nov "music needs hype"): 110-145 BPM, major, bright, steady energy, 2-4 min.
- Playlist (Config.Music, crossfaded, volume ~0.3-0.35):
  | Track | id | why |
  |---|---|---|
  | Scoreline (a), APM Juice "GAME ON" | 1839885070 | "upbeat uplifting guitars and beats", busiest beat (4.4 onsets/s), bright |
  | Big League (c), APM | 1837768143 | ~124 BPM, major, steady |
  | To The Brink, APM | 1842980833 | major, bright, steady |
  | Into a Groove, APM | 1841070181 | ~115 BPM groove, major, steady |
  | Press Start | 99739896065273 | game feel, steady |
- Rejected: Superball, Radioactive (long quiet sections), "GAME OVER" (name), most "Most Used" tracks (hip-hop/vocal, not our audience).
- Owner can swap any track by ear: Config.Music.

## Sound set v2 (code-made, `Audio/sfx_v2/make2.py`, group 33151111, universe Use granted, all Approved)
UI_Tap 90835350365026 · UI_Hover 120027345310007 · UI_Open 117784907849517 · UI_Close 76258214991476 · Card_Deal 139758581164111 · Card_Flip 87102369204036 · Card_Pick 101466415977958 · Card_Freeze 103612827923019 · Card_Burn 107485687744721 · Crumble_Garden 78284932978280 · Crumble_Plastic 125279689402024 · Crumble_Metal 83699135578421 · Crumble_Brick 130692923201986 · Crumble_Concrete 111735287440167 · Rebuild 133509328696606 · Step 102581148294795 · Ting 113164375799351 · Tick 106262203636729 · EvolveRise 113101928118566 · Whoosh 139225906773558 · Combo 105909413179325
- Wired: crumble sound by the prop's material; coins land as Tings climbing a pentatonic ladder through a combo; giant footsteps (scale >= 2); rebuild pop; talent window open/close; card deal/flip/hover/pick/freeze/burn.
- Check done: energy below 150 Hz (phones can't play it). Step/Brick/Concrete got mid-band bodies.

## UI motion (`StarterPlayerScripts.SE_UIFx`)
- Every button of ours: hover 1.05 + glass tick (mouse only), press 0.92 then Back-out release. Buttons with their own scale tweens and full-screen backdrops are skipped.
- TALENTS with picks waiting: a sheen sweeps across the stud button every ~2.5 s and it breathes (1.045). Off under Reduced Motion.
- The talent UI hides during an evolve cutscene; the auto-opened hand waits until the cutscene ends (it used to pop over "YOU EVOLVED").

## VFX kit (`ReplicatedStorage.StompEvolution.StompFX`)
Sprites reused from MEGA BITE's code-keyed sheet (ring, thin ring, star4, orb, flare, speed lines, swirl, beam, sparkle trail, ripple, impact).
- Stomp: impact flash + ground ring (form colour) + star chips + dust. Ground Pound: 3 rings, flare, radial speed lines, star fountain, more dust.
- Prop break: flash + chips in the prop's real colours + dust; tall props a dust column; golden = gold flare, star fountain, gold ring.
- Rebuild: ring + rising sparkles. Golden props: rising gold stars + a soft flare while waiting.
- Evolve: charge (orbs pulled in, swirl) then burst (white flash, 3 rings, star burst, light beam, rising orbs) in the new form's colour. Other players' evolves get the burst too.
- Form auras (tier budget, others at half rate): Stone dust motes; Iron cyan sparks; Magma embers + smoke; Storm violet sparks + trail; Crystal cyan/pink glints; Star gold orbs + stars + flare.
- Giant footsteps (scale >= 2): ring + dust per stride, tiny shake above scale 5.
- Crown holder: gold halo flare + rising stars. Pad buy: ring + star column + flash.
- Budget: others' effects at half count, 40% under Reduced Motion.

## Bugs found and fixed
- `FX` name clash: StompClient already had `local FX = Folder("ClientFx")` further down, so the module calls hit the folder. The module is `SFX` in the client.
- `NumberRange.new(-6s, -8s)` errors (min > max) and it broke the evolve cutscene. VFX calls in the cutscene are now pcall'd: an effect must never break a cutscene.

## Tested in Play
Evolve to Magma and Star (burst, beam, stars), stomp a car (coloured chips, wreck), giant walk at Star (footstep rings/dust, gold aura), music playing (Big League), no errors except the old Star cape texture (86535098135155, open item).
Saved: version 61.
