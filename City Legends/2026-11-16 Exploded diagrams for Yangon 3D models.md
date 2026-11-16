---
tags: [city-legends, yangon, 3d, method, blueprint]
created: 2026-11-16
---
# Exploded diagrams for Yangon 3D models

> Owner (16 Nov 2026): "i think using chatgpt and building a couple of exploded diagrams reference images for the 3d model and using openrouter"

The method is the "Exploded Diagram Method" in [[Brain/Skills/roblox-3d-model-from-sheet/SKILL|3D model from sheet]], step 1a:
- an image model draws every part of an object pulled apart along its axis, each part labelled;
- each labelled part becomes one Blender object (later one MeshPart), named after its label;
- the parts are slid back together to the assembled view.

## The 1:1 rule for real places
- Always ATTACH the real photos and say "copied exactly from the attached photos".
- The sheet gives the PARTS and their shapes. Real sizes, colours, counts and sign text come from the photos and the research notes.
- Text drawn by ChatGPT (for example Burmese on a sign) is never used: it is usually not real Burmese.

## Two image routes
1. **ChatGPT in the owner's Chrome.** This works now (used for the first sheet).
   - Chrome downloads from this ChatGPT tab do not reach `C:\Users\kaung\Downloads`.
   - The browser tool blocks returning image data.
   - What works: lay the image over the page at 1536x1024 and save two full-res zoom captures, then stitch them in Python.
2. **OpenRouter** (one key reaches Gemini image, GPT image and others): `Games/CityLegends/tools/exploded/openrouter_exploded.py` with a job json that lists the real photos.
   - **Owner's steps (once):**
     1. Make a key at openrouter.ai and add a little credit.
     2. In a Windows terminal, run `setx OPENROUTER_API_KEY "your-key"`.
     3. Restart Claude.
   - Claude never types or sees the key. A run makes at most 4 calls.
   - **Status (16 Nov):** the key `CityLegends` is set, with a $10 limit. The account still has $0 credit, so image calls answer 402 "Payment Required". The owner adds credit at openrouter.ai/settings/credits.
   - Image models listed on 16 Nov include `google/gemini-3.1-flash-image` (the default pick: cheap) and `openai/gpt-5.4-image-2`.

## Sheets made
| # | Object | Refs | Sheet | Notes |
|---|---|---|---|---|
| 1 | Kaba Aye Pagoda (pilot district) | `imports/refs/exploded/kaba_aye/Kaba_Aye_Paya_2/3.jpg` (Commons CC0, midday) | `imports/refs/exploded/kaba_aye/kaba_aye_exploded_v1.png` | 9 parts: hti, banana bud, lotus bands, bell, moulding rings, terrace ring of merlons, arched hall drum, entrance porch (pyatthat gable), round base. Plus an assembled view. The bell parts are reusable as the kit for the 158 bare pagodas. |

## Next sheets (planned)
- Yangon trishaw (sidecar bicycle)
- YBS bus stop
- Concrete power pole with transformer and wire bundle
- White street lamp
- Tea-shop low tables and stools
- Betel / food stall
- Roof water tank with stand

All of them have real photos in `Games/CityLegends/build/landmarks/refs/street_kit/`.

![[kaba_aye_exploded_v1.png]]
