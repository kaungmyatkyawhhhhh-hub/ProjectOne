# Sound table: MM Outfit Catalog UI sounds

- **Date:** 2026-11-16
- **Skill:** roblox-game-sounds
- **Source:** our own synthesis in Python (`Audio/make_ui_sounds.py`). No Fish Audio, no stock sounds, no licence needed.
- **Family:** soft, clean boutique sounds, all in **C major pentatonic** (C E G A), so they never clash with each other or the music. The identity of each sound sits at 1–5 kHz, which phone speakers can play.
- **Uploaded to:** the Myanmar Builders Club group (33151111), which owns the experience. All 12 were **Approved** in moderation on 16 Nov.
- **Code:** `ReplicatedStorage.OutfitShowcase.Sounds`. Call `Sounds.Play(name)`. It's pooled (3 copies per id), plays in 2D in SoundService under the SoundGroup `MM_UISounds`, has a per-sound minimum gap so sounds can't stack, adds pitch jitter on taps, and honours the PlayerGui attribute `MMUISoundMuted` (the existing "UI sounds on/off" switch).
- **Listening page:** `Audio/listen.html` (play it on a phone speaker too). Spectrograms: `Audio/spectrograms.png`.

| Event | Name | Asset ID | File | Length | Loudness | Volume | Variants / jitter | Where it plays |
|---|---|---|---|---|---|---|---|---|
| Tap | ui_tap | 116269262550109, 113288982769059, 79907483629932 | ui_tap_1-3.ogg | 0.07 s | -21 LUFS | 0.45 | 3 variants, ±5%, gap 60 ms | every catalog/viewer button (PlayCatalogCue), After Hours controls, item cards |
| Panel open | ui_open | 111245986115535 | ui_open.ogg | 0.26 s | -20 | 0.45 | | ShowroomCollection overlay opens |
| Panel close | ui_close | 133193558362098 | ui_close.ogg | 0.22 s | -21 | 0.40 | | overlay close, viewer close |
| Viewer open (signature) | viewer_open | 83688045996655 | viewer_open.ogg | 0.50 s | -18 | 0.55 | fixed | the cut into the TikTok studio |
| Outfit switch | outfit_switch | 107798392572500 | outfit_switch.ogg | 0.20 s | -20 | 0.45 | ±3% | prev/next outfit in the viewer |
| Buy prompt | buy_prompt | 131016731779360 | buy_prompt.ogg | 0.24 s | -18 | 0.50 | | Buy all, catalog "success" cue |
| Purchase success (signature) | purchase_success | 121628107438233 | purchase_success.ogg | 0.80 s | -17 | 0.60 | fixed | PurchaseUpdated with purchased = true |
| Can't buy | ui_soft_no | 106869751625753 | ui_soft_no.ogg | 0.22 s | -22 | 0.40 | | (available; the card tap now opens the item page) |
| Wishlist add | wishlist_add | 114721442177822 | wishlist_add.ogg | 0.30 s | -19 | 0.50 | | viewer Wishlist when adding |
| Floor arrival | floor_chime | 133369351325197 | floor_chime.ogg | 0.70 s | -20 | 0.40 | | PenthouseWayfinding when the floor changes |

Peaks all at or below -1 dBFS. The stock `rbxasset://sounds/electronicpingshort.wav` (pitched up, one click for everything) was removed from Wardrobe, AfterHoursClient and PenthouseWayfinding.

**Not done:** a real phone-speaker check by ear (Claude can't hear). Listen with `Audio/listen.html`, or in-game on a phone.
