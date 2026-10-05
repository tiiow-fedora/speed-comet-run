"""Homepage thumbnails via the Thumbnail Personalization API. Never prints the key.
usage: python tools/homepage_thumbs.py list
       python tools/homepage_thumbs.py upload FILE [FILE ...]   -> uploads, polls, prints asset ids
       python tools/homepage_thumbs.py activate ID [ID ...]     -> POST /personalization/create
"""
import sys, json, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from rbx import req, multipart, U

API = f"/thumbnail-personalization-api/v1/universes/{U}"

def show(s, t):
    print(s); print(t[:3000] if isinstance(t, str) else t)

def upload(paths):
    ids = []
    for p in paths:
        p = pathlib.Path(p)
        ctype = "image/png" if p.suffix.lower() == ".png" else "image/jpeg"
        body, h = multipart({}, {"files": (p.name, ctype, p.read_bytes())})
        s, t = req("POST", f"{API}/thumbnails/uploads", body, h)
        print(p.name, s, t[:600])
        try:
            j = json.loads(t)
        except Exception:
            continue
        ops = list(j.get("fileToOperationIdDict", {}).values())
        poll(ops)
    return ids

def poll(ops):
    for _ in range(40):
        if not ops: return
        s2, t2 = req("GET", f"{API}/thumbnails/uploads/status?operationIds=" + ",".join(ops))
        print("  status", s2, t2[:800])
        if "pending" not in t2.lower() and "processing" not in t2.lower():
            return
        time.sleep(3)

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "list":
        for path in ["/thumbnails", "/personalization", "/personalization/configs"]:
            print("GET", path); show(*req("GET", API + path))
    elif cmd == "upload":
        upload(sys.argv[2:])
    elif cmd == "activate":
        body = {"homepageThumbnailIds": sys.argv[2:]}
        show(*req("POST", f"{API}/personalization/create", body))
