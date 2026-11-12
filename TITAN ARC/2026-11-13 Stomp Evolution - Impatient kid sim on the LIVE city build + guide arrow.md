# Stomp Evolution - impatient-kid sim on the LIVE city build + the guide arrow (13 Nov 2026, 02:15-03:00, autopilot)

Owner: "ok how do we make the game better" → "start it rn".
- Method: [[Brain/Methods]] impatient-kid simulation, run on the LIVE numbers (Config read from Studio).
- Code: `Calc/livekid.py`; results: `Calc/live_results.txt`.

## Live inputs (read from ReplicatedStorage.StompEvolution.Config)
- **Props** (need m / mass / coins): Flower 0/1/1, Mailbox 0/1.5/1, Bin 0/2/2, Bike 2.05/4/3, Car 3.5/14/8, Bus 6/45/22, House 10/150/60, ShopRow 18/520/180, Tower 32/1900/550.
- **Forms** at 1.9 / 2.4 / 3.0 / 4.5 / 8 / 13 / 21 m. Mass needed: 24 / 128 / 386 / 2,270 / 25,354 / 191,954 / 1.4 M.
- **POWER card hand:** every third of a form.
- **Other numbers:**
  - welcome gift: 10 coins;
  - Ground Pound: first at stomp 6, then every 15th (x6, +3 props);
  - first golden prop at 22-32 s, golden rate 1/200;
  - pads only on the main road (x 40 / 330 / 800);
  - 15-step quest chain.
- **City build:** props are spread over 7 streets. A kid finds the next bigger kind by wandering: 3-12 s of searching each time.
- **Calm pass:** a stomp gives a little less juice (1.3 vs 1.6).

## Kid model
- The owner's model: a boredom meter, patience lognormal (median 11 s), rewards that wear off, NEW things count most; 2,000 kids per version.
- Live extras:
  - hold = auto stomp, with time per stomp from the density of each prop kind;
  - the evolve cutscene freezes boredom;
  - each card hand costs 2-5 s;
  - the body grows in visible 4% steps (a small reward each).

## Results (5-min stay at median patience)
| Version | 60 s | 2 min | 3 min | 5 min | 5 min @7 s | 5 min @16 s | Longest NEW gap |
|---|---|---|---|---|---|---|---|
| A LIVE | 90% | 68% | 47% | **11%** | 1% | 36% | 70 s |
| B + guide arrow | 100% | 100% | 97% | **67%** | 29% | 91% | 60 s |
| C + "NEW!" smash index | 100% | 100% | 97% | 67% | 28% | 90% | 59 s |
| D + playtime gifts 1/3/5 min | 100% | 100% | 97% | 70% | 32% | 90% | 54 s |
| E + city event every 3 min | 100% | 100% | 97% | 67% | 32% | 89% | 54 s |
| F + pads at every crossing | 100% | 100% | 100% | 73% | 36% | 93% | 52 s |
| G + golden 1 in 80 | 100% | 100% | 99% | 74% | 38% | 93% | 51 s |
| H + city event every 90 s | 100% | 100% | 99% | **79%** | 44% | 94% | 48 s |

Also tested (no gain, within noise): compressing the form gates (Magma 3.9, Storm 6.5, Crystal 10), cars at 3.2 m, buses at 5 m, and new card art in every hand.

### What it says
1. **The city made finding things the problem.** On the straight road the next bigger thing was always ahead. In a city, kids wander and quit. **The guide arrow is the biggest lever by far** (5 min: 11% → 67%).
2. Kids who still quit are stuck at IRON → MAGMA (386 → 2,270 mass). The fixes are things that HAPPEN (events, golden, gifts, pads nearby), not cheaper gates.
3. Regular city events (every 90 s) are the next biggest win: +6-12 points.

## Built tonight: guide arrow (`StarterPlayerScripts.SE_Guide`)
- **Where it points, in order:**
  1. an upgrade pad you can afford (from quest 3 on, so never in the first seconds);
  2. the current quest's prop;
  3. the biggest kind you can smash that you haven't smashed yet, with a "NEW!" tag;
  4. if nothing smashable is near, the nearest thing you can smash.
- **When it shows:** never while a window or the cutscene is up, and never when smashable things are right next to you (calm).
- **Look:** a chunky gold drawn arrow bobbing above the target, plus a gold arrow on the screen edge when the target is off screen. The green HEIGHT icon vanished against the grass.
- Checked in Play: at 2.06 m it pointed to the nearest Bike ("NEW!"), the edge arrow showed with the bike off screen, and it hid while the card hand was open. Saved.

## Next (in this order, from the sim)
1. City event every ~90 s (giant toy robot / golden rush / bus parade, x5 Mass for 20 s, everyone together = also the social moment).
2. Upgrade pads at the crossings (or one pad trio per district).
3. Playtime gifts at 1 / 3 / 5 min.
4. Golden props 1 in 80.
5. "NEW!" smash index popup.

It's a model: the real check is the onboarding funnel after the next test.
