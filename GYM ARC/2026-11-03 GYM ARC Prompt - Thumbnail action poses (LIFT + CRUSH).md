---
date: 2026-11-03
tags: [gymarc, thumbnails, prompt]
---
# Prompt: action poses for thumbnails B (LIFT) and C (CRUSH)
Pipeline that worked (HEIGHT final, 3 Nov): Studio pose -> .obj export -> Claude renders in owner's Blender -> owner ChatGPT paint-over. Front-page rule: ACTION mid-motion + big faces (see Research notes 3 Nov).

```text
GYM ARC: add 2 action poses to the THUMBNAIL SCENE (ServerStorage.ThumbnailScene, edit mode only, never published, never change gameplay). Same bodies/clothes/hair as BACON_4ft and GIANT_7ft (tank top + shorts always on, opaque). Pose with Motor6D Transforms, anchored, each its own Model.
B) LIFT:
- GIANT_lift: the 7'0" giant lifting the 4'0" bacon OVER HIS HEAD with both arms straight up, like a barbell (hands under the bacon's back/hips), chest out, slight lean back, legs wide and strong.
- BACON_lifted: the 4'0" bacon lying flat on the giant's hands, arms and legs flailing out (panic), head tilted toward the camera. Place them together so the hands touch the bacon.
C) CRUSH:
- BARBELL_falling: the heavy barbell tilted ~20 degrees, mid-air, about 6 studs up.
- BACON_run: the 4'0" bacon running away toward the camera: big step (one knee high, other leg back), arms pumping, body leaning forward, head turned back looking at the barbell.
- GIANT_drop: the giant behind, arms down after letting go, confident pose.
Screenshot each from the front and say "ready to export".
NO-CRASH RULES: never loop game/workspace:GetDescendants(); one model per call; edit mode only; no particles/lights/scripts/sounds/SurfaceGuis inside the models; ask me to File > Save first.
```

Owner export: drag ThumbnailScene to Workspace -> right-click each new model -> Export Selection -> Downloads\thumb_export\ (GIANT_lift.obj, BACON_lifted.obj, BACON_run.obj, BARBELL_falling.obj, GIANT_drop.obj) -> back to ServerStorage -> tell Claude "exported".
