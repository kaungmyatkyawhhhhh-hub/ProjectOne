C=dict(dir='piranha', length=2.7196, open_r=6, open_r_top=6, fin_rule='(G/np.maximum(R,1)<0.30)&(R>150)&(B<90)', HS=0.92, WY=0.74, FN=2.1, taper_start=0.5, taper=0.45,
  palette=dict(back=(145,165,185), flank=(245,82,34), belly=(250,140,40)), belly_class='belly',
  ignore=dict(edge=(30,30,30),sclera=(217,218,219),iris=(80,123,160),pupil=(46,47,46),tooth=(234,219,203),mouth=(138,53,51)), ignore_tol=45, tight_tol=36, ignore_tight=dict(brow=(228,82,67),brow2=(215,65,50)),
  back_tint=(50,60,85), fin_edge=(245,120,95), fin_root=(212,48,34), fin_t=7, mouth_col=(120,28,36), brow_col=(226,70,58),
  eye=dict(x_px=983, y_px=279, r_px=58, fwd_deg=18), sclera=True, iris_top=(40,80,130), iris_bot=(120,175,215),
  brows=[dict(pts=[(920,212),(945,203),(970,203),(1000,217),(1027,250)], r_px=9)],
  mouth=dict(corner_px=905, corner_row=392, front_px=1100, front_up_row=318, front_lo_row=348, jaw_front_px=1106, blend_px=60,
             jaw_w=1.0, n_up=3, n_lo=4, tooth_px=20, jaw_back_px=70, round_k=1.8),
  pect_boxes=[(650,330,850,445,"(G/np.maximum(R,1)<0.29)&(R>180)")], pect_splay=45, scale_px=14, colour_mode='sample', cls_blur=7)
