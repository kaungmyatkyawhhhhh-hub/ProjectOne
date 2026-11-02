---
date: 2026-11-02
tags: [gymarc, prompt, performance]
status: done in Studio 2 Nov (see Progress/2026-11-02 GYM ARC Freezing and map holes fixed); owner: streaming radius, publish, live check
---
# Prompt for Claude Code: fix freezing while moving + map holes

```text
GYM ARC (live, players from ads right now): FIX FREEZING WHILE MOVING + MAP HOLES. Read: GYM ARC\2026-11-02 GYM ARC Bug - freezing while moving and map holes.md and GYM ARC - Bug - Night lighting bad and lag spikes while skating.md, ga_1nov_perf (60 FPS pass). Screenshot: GYM ARC\Screenshots\freeze\map_holes_2nov.png.

Measured on the live PC client: memory 1416 -> 1625 MB in 2 min of skating, freeze frames with Network receive 31.8 ms (42%), max frame 120 ms, and ProGymClient:45 "attempt to index nil with 'Position'" (setup <- verify line 93 <- line 111) repeating.

1) ProGymClient: wait for streamed parts (WaitForChild with timeout / StreamingEnabled-safe), never error; verify must not re-run setup that creates connections again (disconnect old ones / guard with a flag). Then grep ALL client scripts for the same pattern (direct indexing of workspace parts that can be streamed out) and fix them.
2) MEMORY LEAK: in a Play test, skate around town for 3 min with the Memory tab (LuaHeap, Instances, Signals); find what grows (connections per retry, cloned UI/effects not destroyed, tables keyed by parts). Fix until memory is flat after the first minute.
3) MAP HOLES: WorldLodClient must never hide parts of buildings (any piece whose model is a building / gym / shop, or anything within 80 studs of the camera). If in doubt, turn WorldLodClient off on PC (keep it for phones only). Make each building / gym model ModelStreamingMode = Atomic (or Persistent for the spawn town), so it streams in whole, no holes.
4) STREAMING BURSTS: StreamingTargetRadius 160, StreamingMinRadius 64, pause mode default; check how many parts stream per step while skating; WorldLodClient / LightAreaClient must not loop over thousands of parts on every camera move (spread work over frames, max ~200 parts per frame).
5) PROOF: before/after with Shift+F5 + MicroProfiler while skating the same route (spawn -> Pro Gym -> town loop): max frame < 33 ms, memory flat, no console errors, screenshot of the same Pro Gym spot without holes. Progress note in Progress\.
```
