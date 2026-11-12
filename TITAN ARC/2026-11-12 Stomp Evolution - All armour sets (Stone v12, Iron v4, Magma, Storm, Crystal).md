# Stomp Evolution - All armour sets (Stone v12, Iron v4, Magma v1, Storm v1, Crystal v1)

Date: 2026-11-12 (owner 18:43: "ok good now continue with all the next ones"). Place saved as version 29 (not published).

## How
- ONE shared armour script for every set: `set_v1.py` (geometry) + `set_paint.py` (paint) + `export_set.py`, switched with SET_THEME = stone / iron / magma / storm / crystal.
- Every set inherits all the fixes from the owner's feedback: Iron v4 geometry, faceted crisp chamfers, hard edges over 32 deg, the detail pass, high-contrast paint, ROBLOX Boy hands with a SurfaceAppearance glove, sabaton boots, angled rims, symmetric.
- About 29-31k triangles per set.
- Only the signature parts and palette change per theme.
- dome_top() bug fixed: it could return the UNDERSIDE of the shoulder dome, so magma chimneys were built inside the shoulder. It now takes the highest surface point within 3 units.

## Sets (design from the approved line-up v5 + owner rules)
| Set | Look | Signature parts |
|---|---|---|
| Stone v12 | sandstone, lime glow, carved glyphs, cracks, moss | 3 lime crystals seated on each shoulder, lime crystal fangs, knee gems, greave spikes |
| Iron v4 | dark forged iron, cyan | blade fin per shoulder, sapphire, crystal fangs, polished trims |
| Magma v1 | black basalt, glowing orange cracks | a basalt CHIMNEY vent (glowing mouth) on each shoulder plus 2 basalt spikes, a spine of basalt spikes down the back, GLOWING soles, orange fangs |
| Storm v1 | electric violet metal | jagged lightning-bolt pieces ROOTED in the shoulders (the line-up had them floating; owner rule: nothing floats), lightning-bolt fins on the forearms, puffy cloud collar, zig-zag glow channels |
| Crystal v1 | pale ice plates, cyan + pink | big cyan/pink crystal clusters on the shoulders, crystal WINGS on the back, crystal shards on the forearms, alternating cyan/pink fangs |

## Asset IDs (group 33151111, all Approved, all textures loaded in Studio)
| Set | Model | Torso | LeftArm | RightArm | LeftLeg | RightLeg |
|---|---|---|---|---|---|---|
| Stone v12 | 138252396562248 | 132706939300282 | 92075542696935 | 96318076405091 | 117201072700673 | 73145645605923 |
| Iron v4 | 83216073305468 | 131686619369699 | 96239379245097 | 76939187330521 | 89513494330436 | 128787975293152 |
| Magma v1 | 95215636020983 | 92305065134493 | 107347107822712 | 89990896464678 | 78688435379046 | 103653919769702 |
| Storm v1 | 127144244448803 | 78868955212783 | 122106301821962 | 117787828540148 | 137538806270035 | 96304316788148 |
| Crystal v1 | 108276924851944 | 118106073155799 | 134407564777110 | 133229166674494 | 111162744147304 | 136891669023399 |

Attachments: the Iron v4 template's attachments plus the json centre shift per part, applied as (dC.x, -dC.y, dC.z).

## Tested
- Studio, Edit: line-up of all 5 next to Korblox (all_sets_lineup.jpg). Every texture Success.
- Play: ArmourKit.Apply on the owner's avatar for each set in turn. All OK: 13 textured parts plus 2 SurfaceAppearance gloves each, accessories kept (magma_on_avatar.jpg).

## Left / later
- Storm: "sparks at the boots" from the line-up not done yet (better as a particle effect in-game than geometry).
- Magma chimneys read a bit thin from far away; could be wider.
- Capes (Iron, Star) = accessories, later. Star set (stage 8) not built yet. Brawler and Starter stages not built.
- Delete Workspace test rigs (*Test, KorTest) and BundleRefs before publishing.
