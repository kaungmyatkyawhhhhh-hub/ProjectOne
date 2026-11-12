---
date: 2026-11-13
tags: [gymarc, prompt, claude-code]
---
# GYM ARC Prompt: debate-kids fixes (lag, fair money, play together, PvP, servers)

From [[2026-11-13 GYM ARC - Debate kids simulation]]. Do them in this order; each is its own commit + Studio save; owner publishes.

1. **Lag pass (phones):** measure first (MicroProfiler / Stats on a phone-size test, memory and FPS in the town, gyms and Gem Mine), then: auto low-end mode on touch devices (LowEnd module already exists: make it default on phones), StreamingEnabled tuning / stream out the far town, merge or cut small parts, cap particles and lights, no new high-triangle models. Target: steady 30+ FPS on a low-end phone. Report before/after numbers.
2. **Fair money:** no full-screen pack before Growth Spurt 2 (or 10 min); remove "worth X / save %" and "30 min only" timers from every offer; add one free daily boost (e.g. 15 min x2 EXP from the daily reward); check no feature is Robux-only.
3. **Play together:** a JOIN FRIEND button (friends in other servers, TeleportToPlaceInstance); SPOT ME: stand by a friend's machine and press SPOT for +EXP to both; crew gym sessions (crew members in the same gym get a small shared bonus).
4. **Real PvP arm wrestling:** challenge any player at a table (both accept), the existing tug-of-war, a ranked score and a weekly board; posing show results partly voted by players in the server.
5. **Servers:** fill the fullest server first (matchmaking), test 12-slot servers, keep NPC gym regulars.
