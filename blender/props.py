"""Generate low-poly space props and export each as FBX.
Run: blender --background --factory-startup --python blender/props.py
Outputs blender/out/{Rock1,Rock2,Rock3,Crystal}.fbx  (all original geometry)."""
import bpy, bmesh, random, math, os
from mathutils import Vector, noise

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)

def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def finish(obj, name):
    obj.name = name
    obj.data.name = name
    # flat shading for the low-poly look
    for p in obj.data.polygons:
        p.use_smooth = False
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    path = os.path.join(OUT, name + ".fbx")
    bpy.ops.export_scene.fbx(filepath=path, use_selection=True, apply_unit_scale=True,
                             global_scale=1.0, mesh_smooth_type="FACE", add_leaf_bones=False,
                             bake_anim=False, axis_forward="-Z", axis_up="Y")
    print("EXPORTED", path, len(obj.data.polygons), "faces")

def rock(name, seed, subdiv):
    clear()
    random.seed(seed)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    off = Vector((seed * 3.1, seed * 1.7, seed * 0.3))
    for v in bm.verts:
        n = noise.noise(v.co * 1.6 + off)
        v.co *= 1.0 + 0.35 * n + random.uniform(-0.08, 0.08)
        v.co.z *= 0.75
    # chop some flat facets
    for _ in range(3):
        nrm = Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))).normalized()
        d = random.uniform(0.6, 0.85)
        for v in bm.verts:
            proj = v.co.dot(nrm)
            if proj > d:
                v.co -= nrm * (proj - d)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, name)

def crystal(name):
    clear()
    bm = bmesh.new()
    # main hexagonal prism with a pointed tip, plus two smaller shards
    def shard(base, height, radius, tilt, rot):
        verts_bottom = []
        verts_top = []
        for i in range(6):
            a = i * math.pi / 3
            verts_bottom.append(bm.verts.new((math.cos(a) * radius, math.sin(a) * radius, 0)))
            verts_top.append(bm.verts.new((math.cos(a) * radius * 0.9, math.sin(a) * radius * 0.9, height * 0.75)))
        tip = bm.verts.new((0, 0, height))
        for i in range(6):
            j = (i + 1) % 6
            bm.faces.new((verts_bottom[i], verts_bottom[j], verts_top[j], verts_top[i]))
            bm.faces.new((verts_top[i], verts_top[j], tip))
        bm.faces.new(list(reversed(verts_bottom)))
        geom = verts_bottom + verts_top + [tip]
        bmesh.ops.rotate(bm, verts=geom, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(tilt, 3, "X"))
        bmesh.ops.rotate(bm, verts=geom, cent=(0, 0, 0), matrix=__import__("mathutils").Matrix.Rotation(rot, 3, "Z"))
        bmesh.ops.translate(bm, verts=geom, vec=base)
    shard(Vector((0, 0, 0)), 3.0, 0.45, 0.0, 0.0)
    shard(Vector((0.35, 0.1, 0)), 1.8, 0.3, 0.45, 0.3)
    shard(Vector((-0.3, -0.2, 0)), 1.4, 0.25, 0.5, 2.6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    finish(obj, name)

rock("Rock1", 1, 2)
rock("Rock2", 2, 2)
rock("Rock3", 3, 1)
crystal("Crystal")
