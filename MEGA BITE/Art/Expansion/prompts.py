import json
STYLE = ("STYLE: MEGA BITE, a Roblox shark game. Bright, chunky stylised 3D \"premium toy\" cartoon, smooth shading with soft rim light, bold readable silhouettes, "
 "saturated ocean colours (turquoise, coral pink, sunny yellow, deep navy, gold accents), simple large shapes that can be built as a low-to-mid poly 3D model, "
 "2-5 flat colour regions per part. NO realism, NO blood, NO wounds, NO text, NO letters, NO numbers, NO logo, NO watermark, NO photo backgrounds, "
 "not slimy, not glossy-plastic AI look, clean edges, NOT a photo.")
LAYOUT_PROP = ("Create ONE image, 1536x1024, a clean ORTHOGRAPHIC model turnaround sheet on a flat solid MAGENTA #FF00FF background (no gradient, no floor, "
 "no shadow on the background, no magenta anywhere in the art). TOP ROW, centred and large: the SIDE view. BOTTOM LEFT: the TOP view (seen from directly above), "
 "the same length as the side view and lined up under it. BOTTOM RIGHT: the FRONT view. All three views the same object, the same scale, flat even lighting, "
 "every view fully inside the frame with wide empty space around it, views not touching each other.")
LAYOUT_CREATURE = LAYOUT_PROP.replace("the same object","the same creature, swimming pose, mouth closed, side view facing RIGHT")
S = []
S.append(("lm_statue", LAYOUT_PROP + " SUBJECT: an ORIGINAL giant sunken stone statue HEAD of an ancient sea king, half buried in sand on the sea floor, about 120 studs tall in game. "
 "Calm noble face with closed eyes, a tall crown of carved stone spikes shaped like coral and shark fins, a thick braided stone beard, cracked weathered sandstone "
 "(warm beige and pale teal patina), patches of pink and orange coral and green sea moss growing on the crown and cheeks, one large crack across the forehead, "
 "a small cave opening under the chin a shark could swim through. Must read as a famous landmark from far away. Not any real or known statue or character. " + STYLE))
S.append(("lm_galleon", LAYOUT_PROP + " SUBJECT: an ORIGINAL sunken wooden pirate-era galleon resting on the sea floor, tilted about 15 degrees, about 160 studs long in game. "
 "Broken middle mast, two shorter masts with torn sails in faded teal and cream, a big round hole in the hull side a shark can swim through, a carved fish figurehead "
 "at the bow (an original friendly fish, not a known character), gold coins spilling from an open treasure chest on the deck, ropes and barnacles, warm brown planks "
 "with lighter edges, soft green moss and pink coral patches. No flags, no skulls, no symbols. " + STYLE))
S.append(("lm_whale_skeleton", LAYOUT_PROP + " SUBJECT: an ORIGINAL giant whale SKELETON lying on the sea floor as a natural ARCH you can swim under and through, about 200 studs long in game. "
 "Huge rounded skull at the front, a long curved spine, tall curved rib bones forming a tunnel, small flipper bones, pale ivory bones with soft cream and light grey "
 "shading, purple and teal sea anemones and small coral growing on the ribs, a few glowing turquoise sea crystals at its base. Friendly cartoon look, not creepy, "
 "no dark horror mood. " + STYLE))
S.append(("lm_lighthouse", LAYOUT_PROP + " SUBJECT: an ORIGINAL sunken stone LIGHTHOUSE standing upright on a rocky underwater hill in a kelp forest, about 150 studs tall in game. "
 "Round tapering tower with red and cream stripes, faded and chipped, a glass lantern room on top that still glows warm yellow, a small balcony rail, a doorway at "
 "the base a shark can swim into and a hole in the upper wall to swim out, tall green kelp strands wrapping around it, starfish and barnacles on the stones. " + STYLE))
S.append(("lm_crystal_arch", LAYOUT_PROP + " SUBJECT: an ORIGINAL natural rock ARCH made of dark navy stone with huge glowing crystals, about 140 studs tall and 180 studs wide in game, "
 "big enough for a giant whale to swim through. Clusters of tall glowing crystals in turquoise, violet and pink grow from its top and both feet, glowing round "
 "mushroom corals and small glowing sea flowers in a garden around its base. Magical, bright and inviting, not scary. " + STYLE))
S.append(("cr_turtle", LAYOUT_CREATURE + " SUBJECT: an ORIGINAL GIANT friendly SEA TURTLE, a gentle giant about 90 studs long in game (much bigger than a shark). "
 "Big domed shell with large hexagonal plates in warm olive green and sandy gold, lighter cream belly plates, broad flippers, a kind old face with big calm eyes, "
 "a small smile, a little patch of coral and two small fish living on the top of its shell (part of the shell). Wise, cute and huge. " + STYLE))
S.append(("cr_whale", LAYOUT_CREATURE + " SUBJECT: an ORIGINAL GIANT friendly BLUE WHALE, a gentle giant about 220 studs long in game. Long streamlined body, deep ocean blue back "
 "with soft lighter blue spots, a pale blue-white grooved throat, small friendly eye with a gentle smile, long pectoral fins with white edges, a wide crescent tail, "
 "small barnacle patches. Calm, majestic, not scary, no teeth. " + STYLE))
S.append(("cr_eel", LAYOUT_CREATURE + " SUBJECT: an ORIGINAL COLOSSAL MORAY-STYLE EEL, a dangerous giant about 160 studs long in game, the guardian of sunken ruins. "
 "Long thick snake-like body in deep teal with bright yellow-green spots, a dark navy back stripe, a long dorsal fin ridge, a big head with a heavy brow, "
 "small glowing yellow eyes, a wide mouth shown CLOSED with a few big cartoon triangle teeth peeking out. Menacing but cartoon, kid friendly, no blood. "
 "Show the body in a gentle S curve in the side view. " + STYLE))
S.append(("cr_kraken", LAYOUT_CREATURE.replace("side view facing RIGHT","side view facing RIGHT, tentacles trailing behind") + " SUBJECT: an ORIGINAL KRAKEN, a GIANT SQUID boss about 250 studs long in game. "
 "Long pointed mantle in deep crimson and coral red with lighter peach spots and a glowing orange fin edge, two huge round glowing yellow eyes with a stern brow, "
 "eight thick arms and two very long tentacles with pale peach suckers and club ends, arms gently curled. Epic and scary-fun for kids, cartoon, no gore, no slime. " + STYLE))
S.append(("kit_opensea", "Create ONE image, 1536x1024, on a flat solid MAGENTA #FF00FF background (no gradient, no floor, no shadow on the background, no magenta in the art). "
 "An exact 4 x 2 grid of 8 ORIGINAL underwater props for a stylised Roblox ocean game, each centred in its own cell with wide empty space, not touching, each shown "
 "in a clean 3/4 view, flat even lighting: TOP ROW: 1) a tall tube SPONGE tower cluster in sunny yellow, 2) a GIANT CLAM half open showing a pink pearl, shell in "
 "lilac and cream, 3) an ANEMONE mound with thick turquoise tentacles with pink tips, 4) a fan of tall SEA WHIPS in orange and red; BOTTOM ROW: 5) a cluster of "
 "round BARREL SPONGES in violet, 6) a ROCK PILLAR stack with green moss and a hole through it, 7) a patch of glowing MUSHROOM CORAL in teal and white, 8) a broken "
 "STONE COLUMN from ancient ruins with carved wave pattern and coral on it. " + STYLE))
json.dump([{"key":k,"prompt":p} for k,p in S], open("prompts.json","w"), indent=1)
for k,p in S: print(k, len(p))
