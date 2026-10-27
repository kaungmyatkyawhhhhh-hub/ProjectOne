---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2)
---
# SPEED ARC - Trails

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- One equipped; bought at the **Trail Booth** (neon booth with a looping demo trail) or the Locker TRAILS tab.
- Dust (start), Chalk Lines (2K, +2% coins), Leaf Swirl (40K, League 2, +3% training), Fire Streak (300K, +5% training), Ice Streak (300K, +5% coins). Lightning (+6% training) and Rainbow (+6% coins) are ready for the Trail Pack (M5).
- Each trail = 1 Trail + 0-1 emitter at the feet, built-in textures only.
- Shows when you walk faster than 22 or race. Your own: full. Others': no emitter, off past 80 studs. Low graphics: emitters at half.

## Where it lives
`Config/Trails`, `Server/Services/LockerService` (attaches it to the character), `Client/Controllers/CosmeticsController` (on/off), `LockerController`.
