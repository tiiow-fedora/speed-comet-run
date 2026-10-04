"""Landmark meshes for the v3 map (same flat-shaded low-poly style as props.py).
Run: blender --background --factory-startup --python blender/landmarks.py
Outputs blender/out/{CometHead,CometTail,SpawnArch}.fbx"""
import bpy, bmesh, math, os, random
from mathutils import Vector, noise
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out"); os.makedirs(OUT, exist_ok=True)

def export(bm, name):
    mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new(name, mesh); bpy.context.collection.objects.link(obj)
    for p in obj.data.polygons: p.use_smooth = False
    bpy.ops.object.select_all(action="DESELECT"); obj.select_set(True); bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, name + ".fbx"), use_selection=True, mesh_smooth_type="FACE",
                             add_leaf_bones=False, bake_anim=False, axis_forward="-Z", axis_up="Y")
    print("EXPORTED", name, len(obj.data.polygons))
    bpy.data.objects.remove(obj)

bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(11)
# comet head: lumpy icosphere
bm = bmesh.new(); bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
for v in bm.verts: v.co *= 1 + 0.18 * noise.noise(v.co * 2.1 + Vector((3, 1, 2)))
export(bm, "CometHead")
# comet tail: long twisted cone pointing +Y (local), faceted
bm = bmesh.new()
rings, seg, length = 7, 8, 6.0
verts = []
for r in range(rings):
    t = r / (rings - 1); rad = 0.95 * (1 - t) ** 1.3 + 0.02; tw = t * 1.2
    ring = [bm.verts.new((math.cos(a + tw) * rad, t * length, math.sin(a + tw) * rad)) for a in [i * 2 * math.pi / seg for i in range(seg)]]
    verts.append(ring)
for r in range(rings - 1):
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new((verts[r][i], verts[r][j], verts[r + 1][j], verts[r + 1][i]))
bm.faces.new(list(reversed(verts[0]))); bm.faces.new(verts[-1])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
export(bm, "CometTail")
# spawn arch: half torus made of 12 chunky segments
bm = bmesh.new()
segs, R, r = 12, 1.0, 0.12
for k in range(segs):
    a0, a1 = math.pi * k / segs, math.pi * (k + 1) / segs
    m = (a0 + a1) / 2
    c = Vector((math.cos(m) * R, math.sin(m) * R, 0))
    g = bmesh.ops.create_cube(bm, size=1.0)["verts"]
    ln = 2 * R * math.sin((a1 - a0) / 2) * 1.05
    for v in g:
        v.co = Vector((v.co.x * r * 2, v.co.y * ln, v.co.z * r * 2))
    bmesh.ops.rotate(bm, verts=g, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(m, 3, "Z"))
    bmesh.ops.translate(bm, verts=g, vec=c)
export(bm, "SpawnArch")
