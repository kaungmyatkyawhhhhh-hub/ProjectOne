"""openrouter_exploded.py (2026-11-16): exploded-view reference sheets for 3D models through OpenRouter.

Owner (16 Nov 2026): "using chatgpt and building a couple of exploded diagrams reference images for the 3d model and
using openrouter". Method: vault `Brain/Skills/roblox-3d-model-from-sheet/SKILL.md` step 1a (Exploded Diagram Method).

The key is the OWNER's: set once in Windows (never paste it in chat, Claude never types it):
    setx OPENROUTER_API_KEY "sk-or-..."      (then reopen the terminal / Claude)
Every call spends the owner's OpenRouter credit: MAX_CALLS caps one run.

    python openrouter_exploded.py <job.json>
job.json:
    {"name": "stupa_bell", "model": "google/gemini-2.5-flash-image",
     "refs": ["../../build/landmarks/refs/.../photo1.jpg", ...],     # REAL photos: the model must copy them, not invent
     "prompt": "...", "n": 1}
Writes build/exploded/<name>_<k>.png + <name>.json (prompt, model, refs, cost info if returned).

1:1 rule: an AI sheet shows how the PARTS come apart and their shapes; real sizes, colours and counts come from the
photos and the research notes, never from the sheet.
"""
import base64
import json
import mimetypes
import os
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "build", "exploded"))
URL = "https://openrouter.ai/api/v1/chat/completions"
MAX_CALLS = 4

STYLE = ("technical EXPLODED-VIEW reference diagram for a 3D modeller. Every part pulled apart along its assembly "
         "axis with thin dashed alignment lines, each part labelled with a short English name, orthographic view, "
         "true proportions copied from the attached real photos, true colours of the real object, clean flat "
         "lighting, no shadows, no perspective, flat solid MAGENTA #FF00FF background, no magenta in the object, "
         "1536x1024. NOT a photo, NOT artistic: a clear engineering sheet.")


def data_url(path):
    mt = mimetypes.guess_type(path)[0] or "image/jpeg"
    with open(path, "rb") as f:
        return "data:%s;base64,%s" % (mt, base64.b64encode(f.read()).decode())


def call(model, prompt, refs):
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        sys.exit("OPENROUTER_API_KEY is not set: the owner sets it with setx (see the header).")
    content = [{"type": "text", "text": prompt + "\n\n" + STYLE}]
    for r in refs:
        content.append({"type": "image_url", "image_url": {"url": data_url(r)}})
    body = {"model": model, "modalities": ["image", "text"], "messages": [{"role": "user", "content": content}]}
    req = urllib.request.Request(URL, data=json.dumps(body).encode(), method="POST",
                                 headers={"Authorization": "Bearer " + key, "Content-Type": "application/json",
                                          "X-Title": "City Legends exploded refs"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.loads(r.read())


def main():
    job = json.load(open(sys.argv[1], encoding="utf-8"))
    base = os.path.dirname(os.path.abspath(sys.argv[1]))
    refs = [os.path.normpath(os.path.join(base, p)) for p in job.get("refs", [])]
    n = min(int(job.get("n", 1)), MAX_CALLS)
    os.makedirs(OUT, exist_ok=True)
    log = {"job": job, "results": []}
    k = 0
    for i in range(n):
        res = call(job.get("model", "google/gemini-2.5-flash-image"), job["prompt"], refs)
        msg = res["choices"][0]["message"]
        for img in msg.get("images", []) or []:
            url = img["image_url"]["url"]
            raw = base64.b64decode(url.split(",", 1)[1])
            k += 1
            p = os.path.join(OUT, "%s_%d.png" % (job["name"], k))
            open(p, "wb").write(raw)
            print(p)
        log["results"].append({"text": msg.get("content"), "usage": res.get("usage"), "id": res.get("id")})
    json.dump(log, open(os.path.join(OUT, job["name"] + ".json"), "w", encoding="utf-8"), indent=1)


if __name__ == "__main__":
    main()
