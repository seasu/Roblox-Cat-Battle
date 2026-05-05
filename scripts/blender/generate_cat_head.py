import bpy
import math

# 1. 清理場景
bpy.ops.wm.read_factory_settings(use_empty=True)

# 2. 建立貓頭 (Rounded Cube Style)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
head = bpy.context.active_object
head.name = "CatHead_Base"

# 加入細分表面 (Subdivision Surface) 營造圓潤感
subdiv = head.modifiers.new(name="Subdiv", type='SUBSURF')
subdiv.levels = 2
subdiv.render_levels = 3
bpy.ops.object.modifier_apply(modifier="Subdiv")

# 稍微壓扁一點，讓它看起來更可愛
head.scale = (1.1, 0.95, 1.0)
bpy.ops.object.transform_apply(scale=True)

# 3. 建立耳朵
def create_ear(side):
    # 使用錐體作為耳朵基礎
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.25, depth=0.4, location=(side * 0.45, 0.45, 0.15))
    ear = bpy.context.active_object
    ear.name = f"CatEar_{'L' if side < 0 else 'R'}"
    
    # 旋轉角度，讓耳朵向兩側傾斜
    ear.rotation_euler = (math.radians(20), 0, math.radians(-side * 25))
    
    # 稍微拉伸一下形狀
    ear.scale = (1.0, 0.4, 1.2)
    return ear

ear_l = create_ear(-1)
ear_r = create_ear(1)

# 4. 合併所有部位
bpy.ops.object.select_all(action='DESELECT')
head.select_set(True)
ear_l.select_set(True)
ear_r.select_set(True)
bpy.context.view_layer.objects.active = head
bpy.ops.object.join()

# 5. 設定材質 (PBR - Principled BSDF)
mat = bpy.data.materials.new(name="CatFace_Material")
mat.use_nodes = True
nodes = mat.node_tree.nodes
bsdf = nodes.get("Principled BSDF")
if bsdf:
    bsdf.inputs['Base Color'].default_value = (0.95, 0.95, 0.95, 1.0) # 白色基礎色
    bsdf.inputs['Roughness'].default_value = 0.85 # 軟萌感 (不反光)

if head.data.materials:
    head.data.materials[0] = mat
else:
    head.data.materials.append(mat)

# 6. 匯出為 FBX (Roblox 標準)
export_path = "white_cat_head.fbx"
bpy.ops.export_scene.fbx(
    filepath=export_path,
    use_selection=True,
    axis_forward='-Z',
    axis_up='Y',
    bake_anim=False,
    mesh_smooth_type='FACE'
)

print(f"建模完成！檔案已儲存至: {export_path}")
