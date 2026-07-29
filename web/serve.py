# -*- coding: utf-8 -*-
"""Local dev server for the handbook web reader.

    python web/serve.py            # http://localhost:8000/web/
    python web/serve.py 8080       # custom port

Serves the repository root so the reader can fetch both
shader-handbook/*.md and shaders/shaders/**/image.glsl.
"""
import functools
import http.server
import os
import socketserver
import sys
import threading
import webbrowser

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))

EXTRA_TYPES = {
    ".md": "text/plain; charset=utf-8",
    ".glsl": "text/plain; charset=utf-8",
    ".frag": "text/plain; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".html": "text/html; charset=utf-8",
}


class Handler(http.server.SimpleHTTPRequestHandler):
    def guess_type(self, path):
        ext = os.path.splitext(path)[1].lower()
        if ext in EXTRA_TYPES:
            return EXTRA_TYPES[ext]
        return super().guess_type(path)

    def end_headers(self):
        # The handbook is edited while the reader is open; never cache.
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()

    def log_message(self, fmt, *args):
        if "404" in (fmt % args):
            sys.stderr.write("404 %s\n" % self.path)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    handler = functools.partial(Handler, directory=ROOT)
    url = "http://localhost:%d/web/" % port
    with Server(("127.0.0.1", port), handler) as httpd:
        print("serving %s" % ROOT)
        print("open    %s" % url)
        print("Ctrl+C to stop")
        threading.Timer(0.6, lambda: webbrowser.open(url)).start()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nbye")


if __name__ == "__main__":
    main()
