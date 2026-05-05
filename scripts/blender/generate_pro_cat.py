import bpy
import math

def cleanup():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_mat(name, color, roughness=0.8, metal=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (*color, 1.0)
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metal
    return mat

# --- 1. 高精細貓頭套 (Inspired by Gemini Image) ---
def build_cat_hood():
    cleanup()
    
    # 建立主頭套
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, location=(0,0,0))
    hood = bpy.context.active_object
    hood.name = "CatHood_Main"
    hood.scale = (1.1, 1.0, 1.1)
    
    # 挖洞 (臉部區域)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(0, -0.3, 0))
    cutter = bpy.context.active_object
    
    mod = hood.modifiers.new(type='BOOLEAN', name="FaceHole")
    mod.object = cutter
    mod.operation = 'DIFFERENCE'
    bpy.ops.object.modifier_apply(modifier="FaceHole")
    cutter.select_set(True)
    bpy.ops.object.delete()
    
    # 耳朵 (蓬鬆感)
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.25, depth=0.1, location=(side*0.4, 0.1, 0.5))
        ear = bpy.context.active_object
        ear.rotation_euler = (math.radians(-15), math.radians(side*10), 0)
        ear.scale = (1.0, 1.2, 2.8)
        
        # 內耳
        bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.18, depth=0.05, location=(side*0.4, 0.15, 0.52))
        inner = bpy.context.active_object
        inner.rotation_euler = (math.radians(-15), math.radians(side*10), 0)
        inner.scale = (1.0, 1.2, 2.5)
        inner.data.materials.append(create_pbr_mat(f"Pink_{side}", (1.0, 0.85, 0.9)))

    # 眼睛與鼻子 (立體物件)
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.06, location=(side*0.2, -0.42, 0.15))
        eye = bpy.context.active_object
        eye.data.materials.append(create_pbr_mat(f"Black_{side}", (0.05, 0.05, 0.05), 0.2))
        
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.05, location=(0, -0.48, 0.05))
    nose = bpy.context.active_object
    nose.data.materials.append(create_pbr_mat("PinkNose", (1.0, 0.7, 0.75)))

    # 合併並導出
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = hood
    bpy.ops.object.join()
    
    # 設置整體材質 (白色毛皮)
    hood.data.materials.append(create_pbr_mat("WhiteFur", (1.0, 1.0, 1.0), 0.9))
    
    bpy.ops.export_scene.fbx(filepath="white_cat_hood_pro.fbx", use_selection=True, axis_forward='-Z', axis_up='Y')
    print("白貓專業頭套產出完成！")

# --- 2. 貓咪連身衣 (包含肉墊細節) ---
def build_cat_suit():
    cleanup()
    
    # 建立軀幹 (稍微胖胖的 Chibi 風)
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    body = bpy.context.active_object
    body.scale = (0.6, 0.4, 0.7)
    bpy.ops.object.transform_apply(scale=True)
    mod = body.modifiers.new(type='SUBSURF', name="S")
    mod.levels = 2
    bpy.ops.object.modifier_apply(modifier="S")

    # 白色肚子 (Belly)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(0, -0.15, 0))
    belly = bpy.context.active_object
    belly.scale = (1.0, 0.3, 1.2)
    belly.data.materials.append(create_pbr_mat("Belly", (0.95, 0.95, 0.95), 1.0))

    # 肉墊 (Paws) - 手腳四處
    paw_locs = [
        (-0.5, -0.2, -0.8), (0.5, -0.2, -0.8), # 腳
        (-0.6, -0.2, 0.4),  (0.6, -0.2, 0.4)   # 手
    ]
    
    for i, loc in enumerate(paw_locs):
        # 主肉墊
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=loc)
        pad = bpy.context.active_object
        pad.scale = (1.0, 0.6, 1.0)
        pad.data.materials.append(create_pbr_mat(f"Pad_{i}", (0.4, 0.25, 0.15), 0.5))

    # 合併導出
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.fbx(filepath="white_cat_suit_pro.fbx", use_selection=True, axis_forward='-Z', axis_up='Y')
    print("白貓專業連身衣產出完成！")

build_cat_hood()
build_cat_suit()
