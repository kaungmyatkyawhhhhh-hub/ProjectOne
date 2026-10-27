"""Write src/manifest.json: every .lua file under src with its Studio class and path.

Naming (like Rojo): Name.server.lua -> Script, Name.client.lua -> LocalScript, Name.lua -> ModuleScript.
Folders become Folders. The first folder is the Roblox service.
"""
import json
import pathlib

SRC = pathlib.Path(__file__).resolve().parent.parent / "src"

entries = []
for f in sorted(SRC.rglob("*.lua")):
    rel = f.relative_to(SRC).as_posix()
    parts = rel.split("/")
    name = parts[-1]
    if name.endswith(".server.lua"):
        cls, base = "Script", name[: -len(".server.lua")]
    elif name.endswith(".client.lua"):
        cls, base = "LocalScript", name[: -len(".client.lua")]
    else:
        cls, base = "ModuleScript", name[: -len(".lua")]
    entries.append({"file": rel, "class": cls, "path": parts[:-1] + [base]})

(SRC / "manifest.json").write_text(json.dumps(entries, indent=1), encoding="utf-8")
print(f"{len(entries)} scripts in manifest")
