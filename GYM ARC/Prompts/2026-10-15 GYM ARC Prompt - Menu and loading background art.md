---
date: 2026-10-15
tags: [gymarc, prompt, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: main menu and loading screen, new background art (15 Oct)

```text
MAIN MENU + LOADING SCREEN: new background art (replaces menu_art.png on both screens).

1. Upload from Downloads (find IDs with search_asset by exact name):
   - gym_arc_thumbnail2_nologo_1920x1080.png (background, already color graded)
   - gym_arc_logo_3d.png (the GYM ARC 3D stone logo with transparent background)
2. Background: one full-screen ImageLabel with the nologo image, ScaleType Crop, ResampleMode Default. Keep the character fully visible on the right on every screen size (if Crop cuts him off on wide phones, shift the image so the crop comes from the left/empty side). Remove the old menu_art + blurred copy + fade.
3. Logo: gym_arc_logo_3d.png as its own ImageLabel top-left (ScaleType Fit, about 32% of screen height, inside the safe area). Add a soft red glow behind it (ImageLabel with a blurred red glow or UIGradient) so it matches the character's aura.
4. MAIN MENU: tagline "Everyone starts tiny." under the logo, then PLAY (big red CTA) and the Shop/Settings/News buttons stacked under it on the left, over the dark area (left of the barbell plate). Player card bottom-left. Update card bottom-right is fine but must not cover the character.
5. LOADING SCREEN: same background + logo, tip card and progress bar along the bottom-left, nothing covering the character.
6. Add a subtle dark gradient on the left 40% so the buttons/text are readable.
7. Screenshot at 844x390, 667x375, iPad and 1920x1080 for both screens. Commit.
```
