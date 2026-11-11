import sys; sys.path.insert(0,'/tmp/claude-0/fish'); from fishtpl import fish_cfg
C=fish_cfg('f_squid', 5.57, 346, 252, (1147,603,1340,770), [(690,804,0),(1160,1418,0,156,248)], [(690,792,0),(1160,1418,0,331,252)], [(660,795),(1120,1416)],
  None, (200,90,200), (250,215,225), (756,278,58),
  no_magenta_rule=1, magenta_tol=60, ignore_top_rule='(R+G+B<200)|(B>R+60)', skip_comp_boxes=[(1150,40,1430,175),(1150,295,1430,440)],
  pect_top=dict(box=(760,575,965,722), droop=0, z_frac=0.0, hinge_in=0.7, thick=1.1), fin_min_px=300, fin_min_t=2.0, cap_px=40, tail_t=12, NR=44)
