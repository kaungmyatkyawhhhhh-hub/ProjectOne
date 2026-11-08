"""Writes the centreline from tools/riviera/looplink.json into tools/riviera/LoopLink.luau (the two --DATA lines).

    python tools/riviera/looplink_data.py
"""
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
j = json.load(open(os.path.join(HERE, "looplink.json")))
path = ",".join("{%.2f,%.3f,%.2f,%.4f,%.4f,%.2f}" % tuple(p) for p in j["pts"])
old = ",".join("{%.2f,%.2f,%.2f}" % tuple(p) for p in j["old_path"])
lua = os.path.join(HERE, "LoopLink.luau")
src = open(lua, encoding="utf-8").read()
src = re.sub(r"local PATH = \{.*?\} --DATA PATH", lambda m: "local PATH = {" + path + "} --DATA PATH", src, flags=re.S)
src = re.sub(r"local OLD = \{.*?\} --DATA OLD", lambda m: "local OLD = {" + old + "} --DATA OLD", src, flags=re.S)
open(lua, "w", encoding="utf-8", newline="\n").write(src)
print("LoopLink.luau", len(src), "chars,", len(j["pts"]), "path points,", len(j["old_path"]), "old points")
