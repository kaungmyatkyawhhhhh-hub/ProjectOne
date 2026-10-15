---
date: 2026-10-15
tags: [gymarc, prompt, bug]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt:  Store loads slowly (15 Oct)

```text
BUG: the Robux Store took about 10 minutes to load on a phone. It must open instantly.

1. Find why: are GetProductInfo / UserOwnsGamePassAsync calls done one by one, waited on before showing anything, retried with long waits, or called again every time the shop opens? Measure how long it takes now and tell me.
2. Fix:
   - Store each pass/product's name, price, description and icon ID in Config (the Creator Hub values). The Store builds and shows immediately from Config, no waiting.
   - In the background (task.spawn, all items in parallel, once per session at join, cached), call GetProductInfo just to update the price if it changed. If it fails or is slow, keep the Config values. Max 1 retry after 5 seconds, never block.
   - Ownership (OWNED stamps): check passes once at join on the server in parallel and send the result to the client; update the stamps when it arrives. Show "..." on the buy button only for that item until it's known, never a blank shop.
   - Icons: preload the shop icons with ContentProvider:PreloadAsync in the background after the main game loads, so pictures appear right away.
3. Opening the Store a second time must be instant (no rebuilding, just show/hide).
4. Test on the phone emulator with a slow network (Studio network throttling if possible): the Store shows all items with names, prices and icons in under 1 second. Put the before/after time in PROGRESS.md. Commit.
```
