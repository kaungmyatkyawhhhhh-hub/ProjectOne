# 13 Nov: MOSASAURUS (evolution 9), FishKit v3 + relief, from Art/HSE_sheets/mb_hse_mosasaurus.png (owner 13:22: "good").
# A long sea lizard: a crocodile snout with a closed toothy mouth, a glowing orange eye under a heavy brow, a glowing
# orange line along the flank, four flippers (the big front pair from the top view), a shark-like tail.
C=dict(dir='mosa', length=6.4, open_r=4, open_r_top=4, env_px=150, body_x0_px=270, top_x0_px=185, front_box=(1060,570,1412,860),
  bridge_top=[], bridge_bot=[(360,612,2),(770,1112,3)], cap_px=70, stalk_env=False, lip_pad=2, mouth_wall=1, jaw_FN=2.1,
  env_top=[], env_bot=[(360,612),(770,1112)],
  tw_fill=1, tw_interp_ranges=[(450,710),(770,1170)], tw_bulge=0.03, HS=1.0, WY=0.9, FN=2.1, taper_start=0.5, taper=0.0, back_amt=0.05, fin_step=14, fin_grid=18,
  palette=dict(back=(25,85,95), belly=(235,170,70)), belly_class='belly', colour_mode='sample', sample_blur=1.5, sample_mix=0.97,
  ignore={}, ignore_tol=25,
  ignore_circles=[], eye_ignore_k=0, fill_blur=7,
  ignore_polys=[[(1112,268),(1062,246),(1000,256),(948,300),(896,346),(1084,346),(1114,322)], [(518,302),(556,282),(602,280),(608,306),(520,312)]],
  ignore_circles_front=[(1162,669,34),(1310,669,34)], ignore_boxes=[], ignore_boxes_front=[],
  top_w=0.6, bot_w=0.3, front_w=0.0, edge_px=10, bot_inset_px=12, top_inset_px=24, exact_place=1, fin_tips=1, fin_atlas=1, fin_follow_exact=1,
  back_tint=(5,35,40), fin_edge=(10,60,66), fin_root=(30,110,116), fin_t=8, mouth_col=(18,40,42), brow_col=(28,80,90),
  look_fwd=0.25, eye_dome=0.07, eye=dict(x_px=1315, y_px=186, r_px=17, fwd_deg=22), orb_r=0.8, tip_blur=5, eye_style='orb',
  iris_top=(255,150,0), iris_bot=(255,245,140), tooth_col=(240,232,205),
  brows=[],
  mouth=dict(corner_px=1235, corner_row=216, front_px=1515, front_up_row=228, front_lo_row=229, jaw_front_px=1512,
    up_pts=[(1235,216),(1260,219),(1290,229),(1330,233),(1370,232),(1420,233),(1470,231),(1512,228)],
    lo_pts=[(1235,217),(1260,220),(1290,230),(1330,234),(1370,233),(1420,234),(1470,232),(1512,229)],
    wall_back_px=10, blend_px=80, jaw_w=0.86, inner_fwd_px=-10, n_up=7, n_lo=4, tooth_px=18, lo_tooth_k=0.7, tooth_fit=0, tooth_inset=0.97, tooth_w=0.45, tooth_start=0.2, tooth_inset_lo=0.9, inner_w_max_px=16,
    jaw_back_px=110, round_k=1.8, snout_frac=0.2, snout_cap_px=30, round_from=0.8),
  skip_comp_boxes=[(770,320,1112,448)], pect_top=dict(box=(515,529,723,664), droop=40, z_frac=0.55), fin_min_px=500, scale_px=12, NR=34, NA=26)
