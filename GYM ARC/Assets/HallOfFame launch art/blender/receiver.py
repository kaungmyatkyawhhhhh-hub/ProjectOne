"""Tiny local receiver for the GYM ARC Studio exporter: Studio's HttpService POSTs file chunks here.
POST /append?f=<name>   body = text, appended to OUT/<name>
POST /reset?f=<name>    empties OUT/<name>
POST /b64?f=<name>      body = base64 text, appended to OUT/<name>.b64
POST /png?f=<name>&w=&h= the .b64 (raw RGBA) becomes OUT/<name> (PNG)
"""
import base64
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)


def safe(name: str) -> str:
    return os.path.join(OUT, os.path.basename(name))


class H(BaseHTTPRequestHandler):
    def do_POST(self):
        u = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(u.query).items()}
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        name = q.get("f", "out.txt")
        try:
            if u.path == "/append":
                with open(safe(name), "ab") as fh:
                    fh.write(body)
            elif u.path == "/reset":
                open(safe(name), "wb").close()
                if os.path.exists(safe(name) + ".b64"):
                    os.remove(safe(name) + ".b64")
            elif u.path == "/b64":
                with open(safe(name) + ".b64", "ab") as fh:
                    fh.write(body)
            elif u.path == "/png":
                from PIL import Image
                raw = base64.b64decode(open(safe(name) + ".b64", "rb").read())
                w, h = int(q["w"]), int(q["h"])
                Image.frombytes("RGBA", (w, h), raw).save(safe(name))
                os.remove(safe(name) + ".b64")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        except Exception as e:  # report back to Studio
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())

    def log_message(self, *args):
        pass


HTTPServer(("127.0.0.1", 34998), H).serve_forever()
