# Tiny local receiver: Studio POSTs OBJ text, saved under the out folder given (name from the URL path).
import http.server, os, sys, urllib.parse
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        name = os.path.basename(urllib.parse.urlparse(self.path).path) or "unnamed.txt"
        mode = "ab" if "append=1" in self.path else "wb"
        n = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(n)
        with open(os.path.join(OUT, name), mode) as f:
            f.write(data)
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok %d" % len(data))
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", 34999), H).serve_forever()
