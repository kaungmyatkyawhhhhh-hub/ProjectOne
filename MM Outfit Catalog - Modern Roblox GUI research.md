# MM Outfit Catalog — Modern Roblox GUI research

15 November 2026

## What the references show

- Guriță and Vatavu tested 90 interfaces from two UI generators across three product domains. They found repeated visual patterns across the generated samples, even when basic accessibility checks passed. For our game the useful test is whether a screen communicates its own activity as soon as it appears. [DIS 2025 study](https://mintviz.usv.ro/publications/2025.DIS.2.pdf)
- Roblox's documentation shows Berry Avenue RP putting avatar customization one action away, with items organized by category and visible on the avatar. Its Spellbound RPG example ties the interface to the activity by presenting spells as cards. [Roblox UI and UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Current Roblox designer portfolios present interfaces around the actual game system. Kailor's collection and skin examples make the collection itself the subject. That directed our outfit collection toward the real avatar thumbnails and their catalog IDs. [Kailor’s selected work](https://www.kailor.dev/) · [Robax362’s Roblox UI portfolio](https://robax362.dev/)
- Roblox recommends adapting the layout to input and viewport, accounting for the safe area and touch controls, and respecting reduced-motion preferences. [Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design) · [Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)

## Studio application

- The music player uses a small record sleeve, the track name, a playback line, and labeled Back, Pause or Play, and Next controls. On short touch screens it opens high enough to leave the jump control clear.
- The lift uses numbered buttons with the current floor marked “Here”. The list opens near the current floor and scrolls through all 19 stops.
- Pattern Match uses bordered playing cards with one face-down pattern. Symbol names and the pair count communicate progress in addition to color.
- The outfit collection gives the three avatar thumbnails the largest area and keeps their catalog IDs visible. The monochrome Outfit ID panel stays directly accessible and moves up on touch displays to clear the joystick.
- Graphite, warm ivory, and bronze come from the penthouse. Green is used for matched cards. The interface uses short, interruptible motion and retains a shared UI sound preference.

## Verification

Use the Studio device simulator for Galaxy A06, iPhone 17 Pro, iPad 10th Generation, HD 1080, and Xbox One. Check both the room view and an open panel for fit, interaction targets, and input focus. Real-device performance and player preferences require separate playtesting.
