# GYM ARC Prompt - 27b Rarity roll reveal and trainer boost fix

Date: 2026-10-22

Prompt 27 was done in a TRIMMED version (see Progress "2026-10-22 GYM ARC Trainer Agency redesign"). Now build the part that was skipped. Everything needed is below; you don't need to redo the rest of prompt 27.

1. RARITY-SCALED ROLL REVEAL (replaces the card back + flip). The rarer the trainer, the longer and bigger the reveal. Keep the full-screen backdrop, the full-body portrait, the rarity pill, the NAME, the boost line, the speech bubble and TAP TO CONTINUE that are already there.
   - Common/Uncommon: the card drops in with a small bounce + pop sound, about 0.6 s.
   - Rare: an orb in the rarity colour floats in, pulses twice, then bursts into the card with a small UI shake + sparks, about 1.2 s.
   - Epic: slower, bigger pulses, a purple tint creeps in from the screen edges, then a bigger particle burst, about 1.8 s.
   - Legendary and above: the screen darkens around the orb, the pulses slow almost to a stop, then a hard white flash, gold light rays, a shockwave ring, the card lands with an overshoot (1.2 -> 1.0) and the NAME slams in last with a hit sound, about 3 s. Mythic/Secret/Eternal use their own colour for the rays and ring.
   - Textures: Downloads\gym_arc_aura_vfx (shockwave_ring, spark_star, rim_glow). Layered sounds.
   - X3: the cards resolve one at a time, sorted so the BEST one is last, then all shown together. A tap during a reveal skips straight to the final view of all cards.
   - Auto Roll: the fast reveal, except Epic or better, which plays the full reveal and stops auto roll.
   - Reduced Motion: no shake, shorter flash.
2. The reveal still says "x2 · 2/5 to Golden". Golden was removed in prompt 33: show the next evolution instead, e.g. "x2 · 2/3 to IRON-BORN".
3. HUGE TRAINER BOOST NUMBERS (+2424%): a bug in the level/evolution maths. Report each tier's boost at LV 1, 20 and max, then fix the formula so one max-level LIMITLESS trainer is around +100-150%, never thousands. MY TRAINERS shows each trainer's real boost and the total: "TOTAL +180% (max +400%)".

TEST on phone: a Common, an Epic and a Legendary reveal, an X3 roll, and MY TRAINERS with a high-level trainer. Short progress note in the vault.
