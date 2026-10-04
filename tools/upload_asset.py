"""Upload a file via Open Cloud Assets API and wait for the operation. Prints the asset id.
Usage: python tools/upload_asset.py <path> <assetType> <displayName> [contentType]"""
import sys, json, time, mimetypes, os
sys.path.insert(0, os.path.dirname(__file__))
from rbx import req, multipart

CT = {".fbx": "model/fbx", ".glb": "model/gltf-binary", ".rbxm": "model/x-rbxm", ".mp3": "audio/mpeg",
      ".ogg": "audio/ogg", ".wav": "audio/wav", ".png": "image/png", ".jpg": "image/jpeg"}
OWNER = "418736264"

def upload(path, asset_type, name, ctype=None):
    ctype = ctype or CT[os.path.splitext(path)[1].lower()]
    meta = {"assetType": asset_type, "displayName": name, "description": "+1 Speed Comet Run asset (original, generated)",
            "creationContext": {"creator": {"userId": OWNER}}}
    body, h = multipart({"request": json.dumps(meta)}, {"fileContent": (os.path.basename(path), ctype, open(path, "rb").read())})
    s, t = req("POST", "/assets/v1/assets", body, h)
    if s != 200:
        return None, f"create {s}: {t[:400]}"
    op = json.loads(t)
    opid = op.get("operationId") or op["path"].split("/")[-1]
    for _ in range(60):
        if op.get("done"):
            break
        time.sleep(2)
        s, t = req("GET", f"/assets/v1/operations/{opid}")
        op = json.loads(t)
    if not op.get("done"):
        return None, "timeout " + t[:300]
    if "error" in op:
        return None, json.dumps(op["error"])[:400]
    r = op["response"]
    return r.get("assetId"), r.get("moderationResult", {})

if __name__ == "__main__":
    aid, info = upload(*sys.argv[1:])
    print(json.dumps({"assetId": aid, "info": info}))
