"""Render experience thumbnails (1920x1080) and icons (512x512) from the real game layout.

The track is rebuilt from src/shared/Config.luau with the same rules as src/server/MapBuilder.luau
(zone colors, stage lengths, gaps, islands, gates, pads, shards, planets, comet landmark, spawn arch),
using the same Blender meshes the game loads (blender/out/*.fbx). Nothing is shown that is not in the game.

Run: blender --background --factory-startup --python blender/thumbnails/render_thumbs.py -- [names...]
Outputs: assets/thumbnails/thumb_*.png, icon_*.png
"""
import bpy, math, os, re, sys, random
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "thumbnails"); os.makedirs(OUT, exist_ok=True)
MESH = os.path.join(ROOT, "blender", "out")
cfg = open(os.path.join(ROOT, "src", "shared", "Config.luau"), encoding="utf-8").read()

# ---------- read Config ----------
def rgb(t): return tuple(int(v) / 255 for v in t)
zones = []
for m in re.finditer(r'Name = "([^"]+)", Floor = Color3\.fromRGB\((\d+), (\d+), (\d+)\), Accent = Color3\.fromRGB\((\d+), (\d+), (\d+)\), Rock = Color3\.fromRGB\((\d+), (\d+), (\d+)\)', cfg):
    g = m.groups(); zones.append({"name": g[0], "floor": rgb(g[1:4]), "accent": rgb(g[4:7]), "rock": rgb(g[7:10])})
stages = [(int(a), int(b), int(c)) for a, b, c in re.findall(r"\{ Req = (\d+), Wins = (\d+), Zone = (\d+) \}", cfg)]
assert len(zones) >= 6 and len(stages) >= 15, (len(zones), len(stages))
GRAV, JUMP, W, Y = 80, 16, 40, 200
def ws(s): return min(140, 16 + 12 * math.log(1 + max(s, 0) / 5))
T = 2 * math.sqrt(2 * GRAV * JUMP) / GRAV

# ---------- scene helpers (Roblox (x,y,z) -> Blender (-x, z, y)) ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
def B(x, y, z): return Vector((-x, z, y))
mats = {}
def mat(color, emit=0.0, alpha=1.0):
    key = (tuple(round(c, 3) for c in color), emit, alpha)
    if key in mats: return mats[key]
    m = bpy.data.materials.new("m%d" % len(mats)); m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1); bsdf.inputs["Roughness"].default_value = 0.55
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1); bsdf.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
        try: m.surface_render_method = "BLENDED"
        except Exception: pass
    mats[key] = m; return m
def box(cx, cy, cz, sx, sy, sz, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=B(cx, cy, cz))
    o = bpy.context.object; o.scale = (sx, sz, sy); o.rotation_euler = rot; o.data.materials.append(m); return o
def cyl_y(cx, cy, cz, d, h, m):  # vertical cylinder (Roblox Y axis)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=d / 2, depth=h, location=B(cx, cy, cz))
    o = bpy.context.object; o.data.materials.append(m); return o
def ball(cx, cy, cz, r, m, seg=32):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, radius=r, location=B(cx, cy, cz))
    o = bpy.context.object; o.data.materials.append(m); bpy.ops.object.shade_smooth(); return o
def fbx(name):
    bpy.ops.import_scene.fbx(filepath=os.path.join(MESH, name + ".fbx"))
    o = bpy.context.selected_objects[0]; bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS"); return o
templates = {n: fbx(n) for n in ["Rock1", "Rock2", "Rock3", "Crystal", "CometHead", "CometTail", "SpawnArch"]}
for t in templates.values(): t.hide_render = True; t.location = (0, 0, -9999)
def inst(name, loc, size, m, rot=(0, 0, 0)):
    t = templates[name]; o = t.copy(); o.data = t.data.copy(); scn.collection.objects.link(o); o.hide_render = False
    dims = max(t.dimensions); o.scale = (size / dims,) * 3; o.location = loc; o.rotation_euler = rot
    o.data.materials.clear(); o.data.materials.append(m); return o

# ---------- world ----------
world = bpy.data.worlds.new("W"); scn.world = world; world.use_nodes = True
nt = world.node_tree; bg = nt.nodes["Background"]
grad = nt.nodes.new("ShaderNodeTexGradient"); coord = nt.nodes.new("ShaderNodeTexCoord"); ramp = nt.nodes.new("ShaderNodeValToRGB")
mapn = nt.nodes.new("ShaderNodeMapping"); mapn.inputs["Rotation"].default_value = (0, math.radians(-90), 0)
nt.links.new(coord.outputs["Generated"], mapn.inputs["Vector"]); nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"]); nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
ramp.color_ramp.elements[0].color = (0.40, 0.55, 1.0, 1); ramp.color_ramp.elements[1].color = (0.62, 0.45, 1.0, 1)
nt.links.remove(bg.inputs["Color"].links[0]); bg.inputs["Color"].default_value = (0.30, 0.45, 1.0, 1)
bg.inputs["Strength"].default_value = 1.0
bpy.ops.object.light_add(type="SUN", rotation=(math.radians(50), math.radians(10), math.radians(30)))
bpy.context.object.data.energy = 3.5
scn.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
scn.view_settings.view_transform = "Standard"

# ---------- track (mirrors MapBuilder.build) ----------
rng = random.Random(20261003)
def floor(z0, z1, zone):
    L = z1 - z0
    box(0, Y - 2, z0 + L / 2, W, 4, L, mat(zone["floor"]))
    for side in (-1, 1): box(side * (W / 2 + 0.5), Y, z0 + L / 2, 1, 2, L, mat(zone["accent"], 1.5))
    box(0, Y - 9, z0 + L / 2, W * 0.8, 10, L * 0.95, mat(zone["rock"]))
def island(zc, L, zone):
    cyl_y(0, Y - 2, zc, L, 4, mat(zone["floor"])); cyl_y(0, Y - 0.5, zc, L + 2, 0.4, mat(zone["accent"], 1.5))
def gate(z, zone, locked):
    box(0, Y + 13, z, W + 6, 30, 1, mat((1, 0.2, 0.28), 1.5, 0.6) if locked else mat((0.35, 0.9, 0.47), 2, 0.12))
    for side in (-1, 1): box(side * (W / 2 + 2), Y + 13, z, 4, 30, 4, mat(zone["accent"], 1.5))
    box(0, Y + 29, z, W + 8, 3, 4, mat(zone["accent"], 1.5))
def pad(z, final):
    cyl_y(0, Y + 0.2, z, 22, 1, mat((0.9, 0.7, 0.2))); cyl_y(0, Y + 0.15, z, 23, 1.1, mat((1, 0.8, 0.2), 1.5, 0.7))
def shards(z0, z1):
    k = 0; z = z0 + 12
    while z < z1 - 8:
        k += 1; o = box(((k % 3) - 1) * 9, Y + 3, z, 2, 2, 2, mat((0.47, 1, 0.94), 2), rot=(math.radians(45), math.radians(45), 0)); z += 18
z1 = zones[0]
floor(-40, 40, z1)
box(0, Y + 0.5, -20, 14, 1, 14, mat((0.16, 0.43, 0.55)))
arch = inst("SpawnArch", B(0, Y + 13, 22), W + 12, mat((0.51, 1, 1), 1.5)); arch.rotation_euler = (math.radians(90), 0, 0)
z = 40; gateZ = []; padZ = []
for i, (req, wins, zi) in enumerate(stages, start=1):
    zone = zones[zi - 1]; start = z
    prev = stages[i - 2][0] if i > 1 else 0
    gap = 6 if i == 1 else min(45, max(8, ws(prev) * T * 0.5))
    segA = 60 + 8 * i; floor(z, z + segA, zone)
    if i <= 3: shards(z, z + segA)
    z += segA; L = 22 + i
    for _ in range(2):
        z += gap; island(z + L / 2, L, zone); z += L
    z += gap; segB = 70 + 10 * i; floor(z, z + segB, zone)
    if i <= 3: shards(z, z + segB - 20)
    z += segB; gate(z - 6, zone, locked=(i >= 3)); gateZ.append(z - 6)
    padLen = 70 if i == len(stages) else 50; floor(z, z + padLen, zone); pad(z + 25, i == len(stages)); padZ.append(z + 25)
    zz = start
    while zz < z + padLen:   # rocks + crystals like decorate()
        for side in (-1, 1):
            if rng.random() < 0.7:
                x = side * rng.uniform(W / 2 + 12, W / 2 + 70)
                inst("Rock%d" % rng.randint(1, 3), B(x, Y + rng.uniform(-30, 25), zz + rng.uniform(-10, 10)), rng.uniform(4, 14), mat(zone["rock"]),
                     rot=(rng.uniform(0, 6.28), rng.uniform(0, 6.28), 0))
            if rng.random() < 0.35:
                h = rng.uniform(3, 7)
                inst("Crystal", B(side * (W / 2 - 3), Y + h / 2, zz + rng.uniform(-8, 8)), h, mat(zone["accent"], 1.5))
        zz += 22
    z += padLen
# planets (one per zone, alternating sides) + the big blue one
seen = {}
for i, (req, wins, zi) in enumerate(stages):
    seen.setdefault(zi, None)
zoneStart = {}
zc = 40
for i, (req, wins, zi) in enumerate(stages, start=1):
    zoneStart.setdefault(zi, (gateZ[i - 1] - 300))
for zi, zz in zoneStart.items():
    zn = zones[zi - 1]; side = 1 if zi % 2 == 0 else -1
    ball(side * 700, Y + 150, zz + 300, 220, mat(zn["rock"]))
ball(400, Y - 500, z * 0.5, 300, mat((0.24, 0.35, 0.78)))
# comet landmark
head = inst("CometHead", B(0, Y + 70, 340), 56, mat((1, 0.6, 0.25), 1.5))
d = Vector((0, 0.42, 1)).normalized()
t0 = templates["CometTail"]; dims = t0.dimensions
ax = Vector((1, 0, 0)) if dims.x >= max(dims.y, dims.z) else (Vector((0, 1, 0)) if dims.y >= dims.z else Vector((0, 0, 1)))
db = B(0, 0.42, 1).normalized()
tail = inst("CometTail", B(0, Y + 70, 340) + db * 85, 170, mat((1, 0.4, 0.65), 1.2, 0.8))
tail.rotation_mode = "QUATERNION"; tail.rotation_quaternion = ax.rotation_difference(db)

# ---------- runner (blocky avatar like a Roblox character, with a boot trail) ----------
def runner(x, y, z, trail=(0.47, 1, 0.55), leap=0.0):
    skin = mat((1, 0.8, 0.6)); shirt = mat((0.2, 0.55, 1)); pants = mat((0.15, 0.15, 0.3))
    parts = []
    parts.append(box(x, y + 3 + leap, z, 2, 2, 1, shirt))
    parts.append(box(x, y + 4.75 + leap, z, 1.25, 1.25, 1.25, skin))
    for side, ang in ((-1, 35), (1, -35)):
        parts.append(box(x + side * 1.5, y + 3 + leap, z, 1, 2, 1, skin, rot=(math.radians(ang), 0, 0)))
        parts.append(box(x + side * 0.5, y + 1 + leap, z, 1, 2, 1, pants, rot=(math.radians(-ang), 0, 0)))
    parts.append(box(x, y + 2 + leap, z - 7, 1.6, 2.6, 12, mat(trail, 2, 0.55)))
    return parts

def cam(loc, target, lens=28):
    if "Cam" in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects["Cam"])
    cd = bpy.data.cameras.new("Cam"); co = bpy.data.objects.new("Cam", cd); scn.collection.objects.link(co)
    co.location = loc; dvec = Vector(target) - Vector(loc); co.rotation_euler = dvec.to_track_quat("-Z", "Y").to_euler()
    cd.lens = lens; cd.clip_end = 20000; scn.camera = co

shots = {
    # name: (camera rbx pos, target rbx pos, lens, size, runner pos or None, leap)
    "thumb_spawn_hero": ((5, Y + 7, -34), (0, Y + 22, 250), 26, (1920, 1080), (-3, Y, -20), 0),
    "thumb_gap_leap": ((26, Y + 6, 120), (0, Y + 2, 175), 26, (1920, 1080), (0, Y + 6, 150), 4),
    "thumb_aerial_track": ((160, Y + 260, -120), (0, Y, 900), 30, (1920, 1080), None, 0),
    "thumb_locked_gate": ((-14, Y + 8, gateZ[2] - 70), (0, Y + 12, gateZ[2]), 26, (1920, 1080), (0, Y, gateZ[2] - 40), 0),
    "thumb_mars_shards": ((18, Y + 12, gateZ[1] + 30), (0, Y, gateZ[1] + 200), 26, (1920, 1080), (0, Y, gateZ[1] + 70), 2),
    "thumb_event_horizon": ((-60, Y + 60, gateZ[10] - 260), (0, Y + 10, gateZ[12]), 30, (1920, 1080), None, 0),
    "icon_runner_comet": ((4, Y + 5, -30), (0, Y + 30, 220), 30, (512, 512), (0, Y, -20), 0),
    "icon_comet_track": ((0, Y + 30, 120), (0, Y + 68, 340), 34, (512, 512), None, 0),
    "icon_gate_runner": ((-10, Y + 6, gateZ[2] - 50), (0, Y + 13, gateZ[2]), 30, (512, 512), (0, Y, gateZ[2] - 32), 0),
}
want = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else list(shots)
for name in want:
    c, t, lens, size, run, leap = shots[name]
    extra = runner(*run, leap=leap) if run else []
    cam(B(*c), B(*t), lens)
    scn.render.resolution_x, scn.render.resolution_y = size
    scn.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    for o in extra: bpy.data.objects.remove(o)
    print("RENDERED", name)
