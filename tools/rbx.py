"""Open Cloud helper. Loads ../../.env (or ../.env). Never prints the key."""
import os, sys, json, urllib.request, urllib.error, pathlib

def load_env():
    here = pathlib.Path(__file__).resolve()
    for p in [here.parent.parent / ".env", here.parent.parent.parent / ".env"]:
        if p.exists():
            env = {}
            for line in p.read_text().splitlines():
                if "=" in line and not line.strip().startswith("#"):
                    k, v = line.split("=", 1)
                    env[k.strip()] = v.strip()
            return env
    raise SystemExit(".env not found")

ENV = load_env()
KEY = ENV["ROBLOX_API_KEY"]; U = ENV["UNIVERSE_ID"]; P = ENV["PLACE_ID"]
BASE = "https://apis.roblox.com"

def req(method, path, body=None, headers=None, raw=False):
    h = {"x-api-key": KEY}
    if headers: h.update(headers)
    data = body
    if isinstance(body, (dict, list)):
        data = json.dumps(body).encode(); h.setdefault("Content-Type", "application/json")
    r = urllib.request.Request(BASE + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            out = resp.read()
            return resp.status, (out if raw else out.decode(errors="replace"))
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode(errors="replace")

def multipart(fields, files=None):
    import uuid
    b = "----rbx" + uuid.uuid4().hex
    parts = []
    for k, v in fields.items():
        parts.append(f'--{b}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode())
    for k, (fname, ctype, content) in (files or {}).items():
        parts.append(f'--{b}\r\nContent-Disposition: form-data; name="{k}"; filename="{fname}"\r\nContent-Type: {ctype}\r\n\r\n'.encode() + content + b"\r\n")
    parts.append(f"--{b}--\r\n".encode())
    return b"".join(parts), {"Content-Type": f"multipart/form-data; boundary={b}"}

if __name__ == "__main__":
    m, path = sys.argv[1], sys.argv[2].replace("{U}", U).replace("{P}", P)
    s, t = req(m, path)
    print(s); print(t[:3000])
