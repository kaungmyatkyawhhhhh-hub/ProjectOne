import sys; sys.path.insert(0,'/tmp/claude-0/fish'); from fishtpl import fish_cfg
# Clownfish (13 Nov): replaces the Piranha at evolution 2 (owner: "piranha is ugly ... replace with something else for the kids").
# Food-fish template (no jaw, painted eye and smile), 8 spine bones on the old Piranha rig positions so PiranhaClips keep driving it.
C=fish_cfg('clownR', 2.7196, 458, 245, (1014,612,1331,908), [(510,640,-9,213,181),(640,918,25,181,112)], [(512,650,-4,386,444),(733,858,3,463,471)], [(440,606)],
  [(722,318),(745,300),(780,293),(815,300),(850,318),(880,345),(884,360),(872,385),(845,408),(812,428),(775,440),(742,436),(722,415),(712,385),(712,350)],
  (248,122,12), (246,246,242), (1001,243,57),
  top_w=0.75, ignore_top_rule='R>300', cap_px=60, tail_t=18, pect_w_k=1.1, cap_clamp_px=None, skin_eye=1, no_magenta_rule=0, body_sheet='clean.png')
C.update(NR=30, NA=22, fin_step=13, fin_grid=18)      # owner 13 Nov: "dont use lots of triangles" (the first build was 14,046)
C['ignore_polys']=[]      # the pectoral is already painted out of clean.png (clean.py)
C.update(front_box=(1018,605,1318,910), front_w=2.2, front_pow=4)   # 13 Nov: the front view paints the face (one centred smile); fixfront.py cleaned its eyes
