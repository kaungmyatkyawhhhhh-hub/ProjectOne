# 13 Nov: LEVIATHAN (evolution 10), FishKit v3 + relief, from Art/HSE_sheets/mb_hse_leviathan.png (owner 13:22: "good").
# A black-scaled sea dragon: a red sail of glowing spines along the whole back, two horns, a red belly and jaw, glowing gold
# seams, a yellow eye, two fangs; the big red wing-fins come from the top view.
C=dict(dir='levi', length=7.0, open_r=4, open_r_top=4, env_px=150, body_x0_px=215, top_x0_px=175, front_box=(1098,620,1407,885),
  bridge_top=[(228,500,0,218,224),(500,800,0,224,205),(800,1100,0,205,190),(1100,1398,0,190,166)],
  bridge_bot=[(318,448,2),(540,672,2),(965,1250,3)], cap_px=70, stalk_env=False, lip_pad=2, mouth_wall=1, jaw_FN=2.1,
  env_top=[(228,1398)], env_bot=[(318,448),(540,672),(965,1250)],
  tw_fill=1, tw_interp_ranges=[(390,620),(920,1265),(1250,1430)], tw_bulge=0.03, HS=1.0, WY=0.9, FN=2.1, taper_start=0.5, taper=0.0, back_amt=0.05, fin_step=11, fin_grid=14,
  palette=dict(back=(35,35,40), belly=(190,30,25)), belly_class='belly', colour_mode='sample', sample_blur=1.5, sample_mix=0.97,
  ignore={}, ignore_tol=25,
  ignore_circles=[], eye_ignore_k=0, fill_blur=7,
  ignore_polys=[[(1238,284),(1170,282),(1080,298),(988,330),(988,352),(1242,348)], [(368,306),(442,303),(442,324),(368,324)], [(588,316),(668,314),(668,338),(588,338)]],
  ignore_circles_front=[(1198,706,28),(1307,706,28)], ignore_boxes=[], ignore_boxes_front=[],
  top_w=0.6, bot_w=0.3, front_w=0.0, edge_px=10, bot_inset_px=12, top_inset_px=24, exact_place=1, fin_tips=1, fin_atlas=1, fin_follow_exact=1,
  back_tint=(10,10,12), fin_edge=(210,150,10), fin_root=(150,25,15), fin_t=8, mouth_col=(50,8,8), brow_col=(40,40,45),
  look_fwd=0.25, eye_dome=0.07, eye=dict(x_px=1420, y_px=228, r_px=15, fwd_deg=22), orb_r=0.8, tip_blur=5, eye_style='orb',
  iris_top=(255,190,0), iris_bot=(255,255,170), tooth_col=(240,230,200),
  brows=[],
  mouth=dict(corner_px=1340, corner_row=258, front_px=1518, front_up_row=264, front_lo_row=265, jaw_front_px=1515,
    up_pts=[(1340,258),(1370,253),(1400,259),(1430,263),(1460,267),(1490,268),(1515,264)],
    lo_pts=[(1340,259),(1370,254),(1400,260),(1430,264),(1460,268),(1490,269),(1515,265)],
    wall_back_px=10, blend_px=80, jaw_w=0.88, inner_fwd_px=-10, n_up=3, n_lo=0, tooth_px=22, lo_tooth_k=0.7, tooth_fit=0, tooth_inset=0.97, tooth_w=0.45, tooth_start=0.4, tooth_inset_lo=0.9, inner_w_max_px=16,
    jaw_back_px=110, round_k=1.8, snout_frac=0.2, snout_cap_px=30, round_from=0.8),
  skip_comp_boxes=[(960,330,1250,436)], pect_top=dict(box=(640,560,812,668), droop=40, z_frac=0.55), fin_min_px=500, scale_px=12, NR=34, NA=26)
