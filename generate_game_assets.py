import bpy
import math

def cleanup():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def export_fbx(obj, filename):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=filename,
        use_selection=True,
        axis_forward='-Z',
        axis_up='Y',
        bake_anim=False,
        mesh_smooth_type='FACE'
    )
    print(f"匯出成功: {filename}")

def create_pbr_mat(name, color, roughness=0.8):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (*color, 1.0)
        bsdf.inputs['Roughness'].default_value = roughness
    return mat

# --- 1. 貓頭模型 ---
def build_cat_head():
    cleanup()
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    head = bpy.context.active_object
    subdiv = head.modifiers.new(type='SUBSURF', name="S")
    subdiv.levels = 2
    bpy.ops.object.modifier_apply(modifier="S")
    head.scale = (1.1, 0.9, 1.0)
    
    # 耳朵
    for side in [-1, 1]:
        bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.25, depth=0.5, location=(side*0.45, 0.4, 0.2))
        ear = bpy.context.active_object
        ear.rotation_euler = (math.radians(20), 0, math.radians(-side*25))
        ear.scale = (1.0, 0.4, 1.2)
    
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = head
    bpy.ops.object.join()
    head.data.materials.append(create_pbr_mat("Mat_Cat", (0.9, 0.9, 0.9)))
    export_fbx(head, "cat_head_highpoly.fbx")

# --- 2. 貓尾模型 ---
def build_cat_tail():
    cleanup()
    # 使用路徑擠壓建立彎曲尾巴
    bpy.ops.curve.primitive_bezier_curve_add()
    curve = bpy.context.active_object
    curve.data.bevel_depth = 0.12
    curve.data.bevel_resolution = 4
    # 調整控制點營造彎曲感
    p0 = curve.data.splines[0].bezier_points[0]
    p1 = curve.data.splines[0].bezier_points[1]
    p0.co = (0, 0, 0)
    p1.co = (0.3, 0.8, 0.5)
    
    bpy.ops.object.convert(target='MESH')
    tail = bpy.context.active_object
    tail.data.materials.append(create_pbr_mat("Mat_Tail", (0.9, 0.9, 0.9)))
    export_fbx(tail, "cat_tail_curved.fbx")

# --- 3. 巫師帽 ---
def build_wizard_hat():
    cleanup()
    # 帽簷
    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.05)
    brim = bpy.context.active_object
    # 帽身
    bpy.ops.mesh.primitive_cone_add(radius1=0.45, depth=1.2, location=(0,0,0.6))
    cone = bpy.context.active_object
    
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = brim
    bpy.ops.object.join()
    brim.data.materials.append(create_pbr_mat("Mat_Wizard", (0.2, 0.1, 0.4), 0.9))
    export_fbx(brim, "hat_wizard_stylized.fbx")

# --- 4. 英雄小劍 ---
def build_sword():
    cleanup()
    # 刀身
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    blade = bpy.context.active_object
    blade.scale = (0.05, 0.1, 1.0)
    # 護手
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0,0,-0.55))
    guard = bpy.context.active_object
    guard.scale = (0.3, 0.12, 0.05)
    # 握柄
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.4, location=(0,0,-0.8))
    grip = bpy.context.active_object
    
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = blade
    bpy.ops.object.join()
    blade.data.materials.append(create_pbr_mat("Mat_Sword", (0.8, 0.8, 0.8), 0.2))
    export_fbx(blade, "weapon_sword_hero.fbx")

# 執行所有建模任務
build_cat_head()
build_cat_tail()
build_wizard_hat()
build_sword()

print("\n--- 所有 3D 資產已產出完畢！ ---")
