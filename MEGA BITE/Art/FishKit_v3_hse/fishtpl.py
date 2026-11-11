# Food-fish template for FishKit v3: no jaw, painted eye (no eye mesh), fins from the sheet (atlas), pectoral = painted paddle on the flank
def fish_cfg(d, length, body_x0, top_x0, front_box, bridge_top, bridge_bot, tw_ranges, pect_poly, back, belly, eye, **kw):
    import numpy as np
    big=None
    if pect_poly:
        px=np.array(pect_poly,float); c=px.mean(0); big=[tuple(map(int,c+(p-c)*1.22)) for p in px]      # dilated copy: hides the painted fin + its shadow
    C=dict(dir=d, length=length, open_r=4, open_r_top=4, env_px=150, body_x0_px=body_x0, top_x0_px=top_x0, front_box=front_box,
      bridge_top=bridge_top, bridge_bot=bridge_bot, stalk_env=False, cap_px=40, tail_t=13, fin_atlas=1, fin_follow_exact=1,
      tw_fill=1, tw_interp_ranges=tw_ranges, tw_bulge=0.03, HS=1.0, WY=0.9, FN=2.1, taper_start=0.5, taper=0.0, back_amt=0.03, fin_step=9, fin_grid=11,
      palette=dict(back=back, belly=belly), belly_class='belly', colour_mode='sample', sample_blur=1.2, sample_mix=0.97,
      ignore={}, ignore_boxes=[], ignore_circles=[], eye_ignore_k=0, fill_blur=12, top_w=0.75, ignore_top={}, ignore_top_rule='(R>B+30)|((R>190)&(G>190)&(B>190))|(R+G+B<110)', front_w=0.0, bot_w=0.0, edge_px=8, top_inset_px=18, bot_inset_px=12, exact_place=1, cap_clamp_px=8,
      ignore_polys=[big] if big else [], pect_polys=[pect_poly] if pect_poly else [], pect_splay=34,
      back_tint=(20,30,50), fin_edge=(200,150,40), fin_root=(240,200,80), fin_t=8, mouth_col=(120,30,40), brow_col=back,
      eye=dict(x_px=eye[0], y_px=eye[1], r_px=eye[2], fwd_deg=10), no_eye_geo=1, brows=[],
      fin_min_px=400, scale_px=10, scales_end_px=99999, NR=36, NA=28)
    C.update(kw); return C
