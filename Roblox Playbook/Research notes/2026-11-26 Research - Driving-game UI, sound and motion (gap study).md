---
tags: [research, ui, hud, sound, vfx, motion, driving]
created: 2026-11-26
---
# Driving-game UI, sound and motion: the gap study (26 Nov 2026)

Owner: "study Modern Game GUI, no need to study if its already in the vault", then "also the tower defense simulator GUI Animation Motion VFX study", "& Sound VFX too".

**Already in the vault (not repeated here):**
- [[2026-11-11 Bible notes - modern_ui_design]]: premium layering, Roblox tools, 3D in UI, shop layouts, slop tells, kid readability.
- [[Playbook notes - UI deep dive]]: kit, 9-slice, layout across devices, architecture.
- [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]].
- [[2026-11-26 Research - Modern lobby HUD, window motion and UI SFX (TDS)]]: measured window motion, skill-tree VFX, UI sound levels.
- [[2026-11-26 Research - TDS Solar Requiem cutscenes (film look)]].
- MEGA BITE [[2026-11-12 MEGA BITE - UI sound set v3 (Shop, Index, Settings)]]: code-synth UI sound family, how to wire one sound per press.
- The `roblox-ui-pro` skill.

This note only adds what was missing: the top driving games (console and mobile), the 2025-26 trends, phone landscape controls, and racing sound / VFX. It is a web study; tags: **[fact]** with source, **[inference]** ours.

**Limits:** no public UI talks, font names or motion timings were found for Playground, Criterion or Polyphony. The only hard numbers come from Xbox's accessibility guideline and Apple's game-controls guidance.

## Driving games

**Forza Horizon 5 / 6**
- [fact] Roads not driven yet show orange on the map; the driving line is a GPS-style guide that also says brake.
- [fact] Skill readouts and most HUD pieces and notifications can be hidden.
- [fact] Players complain the tach needle is hard to read and ask for a simpler, customisable HUD.
- [fact] FH6 (May 2026) reviews: the menus and pop-ups are almost unchanged since FH4. Finding events on the huge map is tedious, and car-select filtering "fights me more than the AI does".
- [fact] Wheelspin = a slot-style reel on level-up that spins fast, then slows to a stop. Super Wheelspin = 3 prizes.

**Need for Speed Unbound**
- [fact] The graffiti "Tags" effects exist to show state changes ("quite hard to feedback state changes"). Art director: effects "celebrate player actions"; the realistic world keeps them grounded.
- [fact] The effects can be toned down or turned off. The speedo / tach / nitro share one toggle, and the minimap has its own.
- [fact] Chromatic aberration on the HUD drew complaints. Reviews: stylish, but a "mishmash" of styles and constant race chatter.

**Gran Turismo 7**
- [fact] Menus called "dull, lifeless, convoluted"; the hub is the GT Café on a world map.
- [fact] Photo mode Scapes: 2,500+ real-photo backdrops.
- [fact] The roulette ticket was attacked because the prize is decided before the wheel spins (fake odds).

**The Crew Motorfest**
- [fact] Tile-heavy menus with unclear icons, but a "responsive" UI.
- [fact] Each Playlist is a themed mini-campaign whose page shows its theme, cars and rewards.

**Mario Kart World**
- [fact] The map's reading order is tracks, then roads, then land. Track icons are hand-made diorama miniatures, with colour tuned until that order holds. The same map is reused on loading and voting screens.
- [fact] Players criticised the character-select screen and the half-hidden Free Roam.

**Mobile racers**
- [fact] Asphalt Legends Unite: TouchDrive is the default (swipe for routes and stunts, auto throttle); also Tilt and Tap. Tap is most precise but needs about four fingers.
- [fact] Real Racing 3: 7 control schemes, each with adjustable brake / steer assist and traction control.
- [fact] Racing Master: buttons / gyro / wheel, with Auto Throttle and Auto Drift. A reviewer liked auto throttle with manual drift best.
- [fact] CarX Street: tilt by default; buttons can be moved.

## Trends 2025-26
- [fact] A Bonn study of 30 GOTY nominees (2014-2025) found HUDs steadily more minimal, shifting to in-world and context-only information.
- [fact] Apple's Liquid Glass is a big app trend, but no shipped game clearly adopts it. Critics cite readability and the cost of live blur on old hardware.
  - [inference] Glass and blur belong behind menus over a paused world, not on a live HUD on cheap phones.
- [fact] Xbox Accessibility Guideline 101 (Nov 2026):
  - Minimum text: console 26 px at 1080p; PC 18 px; mobile 18 px at 100 DPI (72 px at 400 DPI).
  - Text should scale to 200%.
  - Outline text shown over gameplay.
  - Long lines in sentence case (short labels can be caps).
- [inference] Per-element HUD toggles and an effects-strength slider are now baseline. Heavy bevels and chrome are gone: realism lives in the 3D (dioramas, photo backdrops), not the frames.

## Phone landscape
- [fact] Apple's game-controls guidance:
  - frequent buttons near the thumbs, outside the areas used to move and look;
  - menus along the top edge;
  - controls only when they apply;
  - targets at least 44 x 44 pt.
- [fact] No published landscape thumb-reach heatmap was found (Hoober's study is portrait).
- [inference] Every top mobile racer offers auto throttle. Steering is left / right halves or buttons, with tilt optional. Keep 2-4 thumb actions (steer; brake / drift / nitro on the right).

## Sound
- [fact] NFS Unbound's mix (audio director Nathaniel Daw):
  - Music leads in events. In free roam it comes in when you start driving and then fades so the car stands out; ambient music plays when stopped. There is no always-on radio.
  - The most important sound wins the mix: at speed the engine drops back for wind and passing cars.
  - "It doesn't matter how good your sound design is if the mix isn't clear."
- [fact] Loudness guides (low authority): Audiokinetic's typical RMS is UI -16 dB, music -16, SFX -16, dialogue -12. A reference table gives UI -14 to -18 LUFS, music -18 to -22, reward sounds under 300 ms.
  - [inference] UI clicks at music level or a little above, under 100 ms; music ducks a few dB under a reward stinger.

## Motion and VFX
- [fact] A wider FOV raises perceived speed; strong motion blur lowers it. Players like subtle speed-based shake but often turn blur and shake off.
- [fact] Unbound's effects: some players found them "too anime", PC Gamer called them the best part, and the off switch ended the argument. Chromatic aberration on the HUD was disliked.
  - [inference] They work because they appear only when earned (drift, jump, boost) and show state at the car, where the eye already is.
- [could not verify] The FH wheelspin's tick sound and rarity colours, any racer's shine timing, Asphalt's card reveal. **Next:** record these from gameplay with the watch-video skill.

## For a Roblox mobile-first city driving game (City Legends)
**Copy**
- Auto throttle as an option; brake / drift / nitro on the right thumb; targets 44 pt+; menus on the top edge.
- Minimal driving HUD: speed + nitro bottom right, minimap bottom left, every piece toggleable. Keep the middle third clear (TDS too).
- "Not driven yet" roads tinted on the map: exploring the real city becomes a game.
- Mario Kart World's map order: landmarks (Shwedagon, Sule) as diorama icons, then roads, then land. Reuse the same map on loading screens.
- Effects only when earned (drift, near miss / cut-up, nitro): a burst and a score pop at the car, plus a strength slider.
- Small speed FOV + light shake, no heavy blur.
- Text at least 18 px at phone scale, outlined over gameplay, a font with full Myanmar support.
- Unbound's music rules: swell when you start driving, then duck; lead in races; drop under reward stingers. Short stingers.

**Avoid**
- Fake-odds spins.
- Dense tile menus with unclear icons.
- A car list without quick filters.
- Chromatic aberration on the HUD.
- Constant chatter.
- Live glass blur on the HUD on cheap phones.
- Taking steering away completely.

## Sources
- FH5 credits https://www.mobygames.com/game/174940/forza-horizon-5/credits/ · https://kotaku.com/11-things-i-wish-i-knew-before-starting-forza-horizon-5-1848007497 · https://kotaku.com/before-you-start-five-settings-to-change-in-forza-hori-1848004522 · https://support.forza.net/hc/en-us/articles/4409280058259-Forza-Horizon-5-Accessibility-Support · https://forums.forza.net/t/the-tach-needle-in-fh5-isnt-clear-enough/534510 · https://forums.forza.net/t/simplified-hud/608259 · https://fullcleared.com/reviews/forza-horizon-6-review/ · https://postmode.substack.com/p/forza-horizon-6-review · https://forza.fandom.com/wiki/File:FH4_Wheelspin.jpg
- NFS Unbound https://jalopnik.com/heres-how-need-for-speed-unbounds-radical-art-style-cam-1849832310 · https://www.ea.com/en/games/need-for-speed/need-for-speed-unbound/news/the-world-is-your-canvas · https://gamespot.com/articles/need-for-speed-unbound-players-can-customize-driving-vfxs/1100-6508198/ · https://ea.com/able/resources/need-for-speed-unbound · https://80.lv/articles/a-deep-dive-into-need-for-speed-unbound-s-sound-design · https://pcgamer.com/need-for-speed-unbounds-wild-visual-effects-are-actually-the-best-part
- GT7 https://www.videogameschronicle.com/review/gran-turismo-7-2/ · https://www.playstation.com/en-gb/editorial/how-gran-turismo-7-harnesses-the-power-of-ps5/ · https://www.gamepur.com/guides/are-roulette-tickets-rigged-in-gran-turismo-7
- Motorfest https://www.techradar.com/gaming/consoles-pc/the-crew-motorfest-review-occasionally-spectacular · Mario Kart World https://nintendoeverything.com/mario-kart-world-dev-discusses-how-the-map-was-designed/
- Mobile https://www.pocketgamer.com/asphalt-9-legends/asphalt-9s-stripped-back-controls-are-the-best-way-to-play-the-game-heres-five-r/ · https://wikipedia.com/wiki/Real_Racing_3 · https://www.unrealengine.com/en-US/developer-interviews/racing-master-brings-authentic-racing-action-and-best-in-class-graphics-to-mobile-and-other-platforms · https://traxion.gg/carx-street-review-ios-leads-the-way-for-carxs-move-to-open-world/
- Trends https://bonndoc.ulb.uni-bonn.de/xmlui/handle/20.500.11811/14207 · https://www.creativebloq.com/web-design/ux-ui/its-time-to-stop-the-apple-inspired-obsession-with-glass-ui-before-it-starts · https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101 · https://developer.apple.com/design/human-interface-guidelines/game-controls
- Sound / speed https://blog.audiokinetic.com/loudness-processing-best-practice-chapter-3-scalable-loudness-processing-for-games/ · https://rd.springer.com/chapter/10.1007/978-3-319-55834-9_14 · https://www.operationsports.com/why-is-speed-so-hard-to-capture-in-racing-games/
