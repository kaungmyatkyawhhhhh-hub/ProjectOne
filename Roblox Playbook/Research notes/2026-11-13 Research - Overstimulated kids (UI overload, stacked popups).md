---
date: 2026-11-13
tags: [research, kids, ui, cognitive-load, method]
---
# Research: overstimulated kids (UI overload, stacked pop-ups)

Why: on 13 Nov in Stomp Evolution, a boss kill fired four things at once (DEFEATED card + evolve card + AREA UNLOCKED + Coin Rain banner). The combo counter sat on top of the card picker's "Later" button, and the talent hand opened over the evolve card. The owner asked for a sim that catches this before players see it.

## Findings
- **What kids can hold at once:** visual working memory roughly doubles between ages 5 and 10, reaching the adult level of about 3-4 items. Young children hold about 2 objects, and with multi-feature objects they often forget either the shape or the colour. Sources: Riggs et al. 2006, J Exp Child Psychol 95(1); Forsberg, Adams & Cowan 2022, Developmental Science; Simmering 2012 (about 3-4 items between 5 and 7 years with an easier task).
- **Pop-ups pull attention away from the goal:** a 2×2 experiment with 240 students found that interface complexity and pop-up interference each hurt attention and retention, and the two together were worst (PMC12646897, 2025). Pop-ups capture attention "exogenously" and disrupt goal-directed processing.
- **Simultaneous notifications:** when several fire close together, showing them all at once makes them overlap into a pile the player can't read. The fix is a queue with priorities, important ones prominent and minor ones subtle or suppressed (bugnet.io notification-queue and notification-system guides).
- **Kids and interfaces (NN/g, testing ages 3-12):** a good design reduces cognitive load. In their tests, 7-year-olds got confused when the screen didn't make clear how to win, and audio instructions were blocked by other sound.
- **Mobile UI bloat:** over years of updates, mobile game interfaces swell with buttons and endless pop-ups (Donut Lab). Clutter is the top UI mistake in the industry checklists (bugnet, sunday.gg, Starloop).
- **Flashing:** keep flashes under 3 per second (WCAG 2.3.1 "three flashes" photosensitivity guideline; known standard, not re-fetched here).

## Model assumptions (estimates, not measured)
- **Attention slots by age:** 5-6 y = 2, 7-9 y = 3, 10-12 y = 3.5.
- **Weights:** a modal window or full card counts 2, a big centre card 1.5, a banner 1, a toast 0.5, a flash or shake 1 (for 0.3 s), a sound sting 0.5.
- **Reading speed:** about 1.5 words/s at age 7 and about 3 words/s at age 10 (estimate; a key message must stay up long enough to read).

## Sources
- [Riggs et al. 2006, visual WM capacity 5-10 y](https://repository.essex.ac.uk/13192/)
- [Forsberg, Adams & Cowan 2022](https://pmc.ncbi.nlm.nih.gov/articles/PMC10029097)
- [Simmering 2012](https://eric.ed.gov/?id=EJ957845)
- [Pop-up interference experiment 2025](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12646897/)
- [Notification queue](https://bugnet.io/blog/how-to-implement-a-notification-queue-and-popup-system)
- [Notification system players don't hate](https://bugnet.io/blog/how-to-build-a-notification-system-players-dont-hate)
- [NN/g kids cognition](https://www.nngroup.com/articles/kids-cognition/)
- [Donut Lab mobile interface](https://medium.com/donut-lab/on-the-razors-edge-how-to-make-a-mobile-game-interface-6f2e4c60e9d2)
