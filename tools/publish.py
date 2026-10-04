"""Build with Rojo and publish to PLACE_ID via Open Cloud Place Publishing.
Usage: python tools/publish.py [Saved|Published]"""
import sys, os, subprocess, json
sys.path.insert(0, os.path.dirname(__file__))
from rbx import req, U, P
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
vt = sys.argv[1] if len(sys.argv) > 1 else "Published"
subprocess.run(["rojo", "build", "-o", os.path.join(root, "game.rbxl"), os.path.join(root, "default.project.json")], check=True)
data = open(os.path.join(root, "game.rbxl"), "rb").read()
s, t = req("POST", f"/universes/v1/{U}/places/{P}/versions?versionType={vt}", data, {"Content-Type": "application/octet-stream"})
print(s, t[:500])
