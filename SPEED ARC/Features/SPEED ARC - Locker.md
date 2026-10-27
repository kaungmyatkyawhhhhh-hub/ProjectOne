---
date: 2026-10-28
tags: [speedarc, feature]
status: M2 tabs (SHOES, TRAILS); more tabs in M5
---
# SPEED ARC - Locker

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- One window from the LOCKER button (left menu), the Shoe Shop and the Trail Booth.
- Tabs: SHOES, TRAILS. Cards in a row you can scroll: art (3D shoe / trail ribbon), name, bonus, price or OWNED / EQUIPPED, locked items dark with how to get them.
- Windows use the UI kit's `UIKit.window` (dimmed screen, slanted title tab, X button, one window at a time) and `UIKit.tabs`.

## Where it lives
`Client/Controllers/LockerController`, `MenuController` (left menu + shop prompts), `Shared/UIKit` (window, tabs).
