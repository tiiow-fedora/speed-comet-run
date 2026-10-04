"""Render the 512x512 game icon: ringed planet, glowing comet track, '+1' text.
Run: blender --background --factory-startup --python blender/icon.py"""
import bpy, math, os
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
scn.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE_NEXT"
scn.render.resolution_x = scn.render.resolution_y = 512
scn.render.film_transparent = False
try:
    scn.view_settings.view_transform = "Standard"
except Exception:
    pass

def mat(name, color, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    if strength > 0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Strength"].default_value = strength
    bsdf.inputs["Roughness"].default_value = 0.6
    return m

# world: deep space gradient-ish
world = bpy.data.worlds.new("W"); scn.world = world; world.use_nodes = True
bg = world.node_tree.nodes["Background"]; bg.inputs[0].default_value = (0.006, 0.004, 0.02, 1); bg.inputs[1].default_value = 1.0

# stars
import random; random.seed(7)
star = mat("Star", (1, 1, 1), 8)
for i in range(70):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.02, 0.06), location=(random.uniform(-6, 6), 8, random.uniform(-6, 6)))
    bpy.context.object.data.materials.append(star)

# planet + ring
bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=2.0, location=(1.6, 4, 1.4))
planet = bpy.context.object; planet.data.materials.append(mat("Planet", (0.45, 0.22, 0.85)))
bpy.ops.object.shade_flat()
bpy.ops.mesh.primitive_torus_add(major_radius=3.0, minor_radius=0.12, location=(1.6, 4, 1.4), rotation=(math.radians(18), math.radians(-28), 0))
bpy.context.object.data.materials.append(mat("Ring", (0.2, 0.75, 1.0), 1.5))

# glowing track ribbon swooping toward the camera
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 0, 0))
track = bpy.context.object
track.scale = (0.9, 9, 1); track.location = (-0.6, 2.5, -2.2); track.rotation_euler = (math.radians(12), 0, math.radians(18))
track.data.materials.append(mat("Track", (0.15, 0.12, 0.3)))
for side in (-1, 1):
    bpy.ops.mesh.primitive_cube_add(size=1)
    r = bpy.context.object
    r.scale = (0.05, 9, 0.05); r.location = (-0.6 + side * 0.48 * math.cos(math.radians(18)), 2.5 + side * 0.48 * math.sin(math.radians(18)), -2.15)
    r.rotation_euler = (math.radians(12), 0, math.radians(18))
    r.data.materials.append(mat("Rail", (0.2, 0.85, 1.0), 2.5))

# comet: glowing head + tail cone
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.45, location=(-0.9, 0.5, -0.5))
bpy.context.object.data.materials.append(mat("Comet", (1.0, 0.75, 0.2), 2.5))
bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.42, depth=2.6, location=(0.25, 1.2, 0.35), rotation=(math.radians(-60), 0, math.radians(-55)))
bpy.context.object.data.materials.append(mat("Tail", (1.0, 0.4, 0.1), 1.2))

# "+1" text
bpy.ops.object.text_add(location=(-3.3, -1, 0.9), rotation=(math.radians(90), 0, 0))
t = bpy.context.object; t.data.body = "+1"; t.data.size = 2.6; t.data.extrude = 0.12
t.data.bevel_depth = 0.03
t.data.font = bpy.data.fonts.load("C:/Windows/Fonts/arialbd.ttf")
t.data.materials.append(mat("Text", (1.0, 0.78, 0.1), 1.0))

# camera + light
bpy.ops.object.camera_add(location=(0, -9, 0), rotation=(math.radians(90), 0, 0))
cam = bpy.context.object; scn.camera = cam; cam.data.lens = 40
bpy.ops.object.light_add(type="SUN", location=(0, -5, 5), rotation=(math.radians(50), 0, math.radians(20)))
bpy.context.object.data.energy = 3.0
try:
    scn.eevee.use_bloom = True
except Exception:
    pass
scn.render.filepath = os.path.join(OUT, "icon_512.png")
bpy.ops.render.render(write_still=True)
print("RENDERED", scn.render.filepath)
