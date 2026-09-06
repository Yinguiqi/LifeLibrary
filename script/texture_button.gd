extends TextureButton

@onready var menu := $"../../../UI/PopupMenu"
@onready var book := $".."
@export var book_id : String
const CONFIG_PATH := "user://config.ini"
const MONITOR_SCENE = preload("res://scenes/3DMonitor.tscn")
@onready var sub_viewport = $"../../../PanelContainer/SubViewportContainer/SubViewport"
@onready var panel_container = $"../../../PanelContainer"
@onready var book_cover: TextureRect = $"../BookCover"
@onready var books_container = $"../.."

# 左键按钮（已移到 book.gd 统一处理，这里保留占位）
func _on_pressed() -> void:
	pass

# 右键按钮（已移到 book.gd 统一处理，这里保留占位）
func _on_gui_input(event: InputEvent) -> void:
	pass
# 菜单选择逻辑
func _on_menu_pressed(id: int) -> void:
	match id:
		0:
			edit_current_book()
		1:
			open_book_cover_texture()
		2:
			setup_3d_monitor()
		3:
			open_book_of_folder()
		4:
			delete_book_by_id()
# 在其他脚本中调用：
func edit_current_book() -> void:
	print(book.data_ref.id)
	var current_book = book.data_ref
	if current_book:
		# 将你的 Book 对象转换为字典
		var book_dict = {
			"book_id":current_book.id,
			"name": current_book.name,
			"author": current_book.author,
			"rel_path": current_book.rel_path,
			"book_texture": current_book.book_texture,
			"book_cover_texture": current_book.book_cover_texture,
			"introduction": current_book.introduction,
			"group_name": current_book.group_name
		}
		
		# 获取窗口实例并加载数据
		var window = preload("res://scenes/add_book_window.tscn").instantiate()
		add_child(window)
		window.load_book_data(book_dict)

	
# 复制书籍文件方法
func copy_file(src_path: String, dst_path: String) -> int:
	var src = FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		push_error("无法打开源文件: " + src_path)
		return ERR_CANT_OPEN

	var dst = FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		push_error("无法打开目标文件: " + dst_path)
		return ERR_CANT_OPEN

	dst.store_buffer(src.get_buffer(src.get_length()))
	return OK

func delete_book_by_id():
# 1. 删除数据
	LibraryManager.delete_book_by_id(book.data_ref.id)
	LibraryManager.book_x -= book.book_scale_width
	LibraryManager.book_x -= LibraryManager.book_spacing
	books_container.remove_child(book)
	book.queue_free()
	books_container.is_dragging = false
	books_container.position.x = LibraryManager.books_container_x
	books_container._relayout_books()

	
func open_book_of_folder():
	var path = LibraryManager.base_path + book.data_ref.rel_path
	var dir_path = path.get_base_dir()
##	var pdf_path = "D:/资源/文章类/电子书/专业书籍/游戏设计艺术（第3版）[[美] Jesse Schell](1).pdf"
	OS.shell_open(dir_path)

func setup_3d_monitor():
	# 判断是否为空
	if book.data_ref.book_cover_texture == "" or book.data_ref.book_cover_texture == null:
		print("111")
		return  # 不执行
	# 判断文件是否存在
	if not FileAccess.file_exists(book.data_ref.book_cover_texture):
		return  # 文件不存在，不执行
	# ---------- 打开整个 3D 面板 ----------
	panel_container.visible = true
	
	# 1. 确保清空旧的 3D 监看器
	for child in sub_viewport.get_children():
		child.queue_free()

	# 2. 实例化新的 3D 场景
	var monitor_instance = MONITOR_SCENE.instantiate()
	sub_viewport.add_child(monitor_instance)

	# 3. 查找 MeshInstance3D 节点
	var cube_mesh_instance = monitor_instance.find_child("MeshInstance3D")
	
	if cube_mesh_instance == null or not cube_mesh_instance.mesh is BoxMesh:
		push_error("3DMonitor 场景中未找到 BoxMesh 节点或节点名称不正确！")
		return

	# 4. 配置长方体的材质和尺寸
	_apply_texture_and_size(cube_mesh_instance)


func _apply_texture_and_size(mesh_instance: MeshInstance3D):
	var mesh := ArrayMesh.new()

	var tex_size: Vector2 = book.book_texture.get_size()
	var scale_factor = 1.0 / tex_size.y
	var w = tex_size.x * scale_factor     # 书宽
	var h = tex_size.y * scale_factor    # 书高
	var d = 0.7     # 厚度
	var hw = w
	var hh = h
	var hd = d

	# --- 0 封面 (Z+)
	_add_surface(mesh, [
		Vector3(-hw, -hh, hd),
		Vector3(hw, -hh, hd),
		Vector3(hw, hh, hd),
		Vector3(-hw, hh, hd)
	], book.book_texture)

	# --- 1 封底 (Z-)
	_add_surface(mesh, [
		Vector3(hw, -hh, -hd),
		Vector3(-hw, -hh, -hd),
		Vector3(-hw, hh, -hd),
		Vector3(hw, hh, -hd)
	], book.book_texture)

	# --- 2 书脊 (X-)
	_add_surface(mesh, [
		Vector3(-hw, -hh, -hd),
		Vector3(-hw, -hh, hd),
		Vector3(-hw, hh, hd),
		Vector3(-hw, hh, -hd)
	], book.book_cover_texture)

	# --- 3 书右侧页 (X+)
	_add_surface(mesh, [
		Vector3(hw, -hh, hd),
		Vector3(hw, -hh, -hd),
		Vector3(hw, hh, -hd),
		Vector3(hw, hh, hd)
	], book.book_cover_texture)

	# --- 4 顶部 (Y+)
	_add_surface(mesh, [
		Vector3(-hw, hh, hd),
		Vector3(hw, hh, hd),
		Vector3(hw, hh, -hd),
		Vector3(-hw, hh, -hd)
	], Color(0.15, 0.08, 0.03))

	# --- 5 底部 (Y-)
	_add_surface(mesh, [
		Vector3(-hw, -hh, -hd),
		Vector3(hw, -hh, -hd),
		Vector3(hw, -hh, hd),
		Vector3(-hw, -hh, hd)
	], Color(0.136, 0.084, 0.073, 1.0))

	mesh_instance.mesh = mesh
	print("📚 渲染简洁版书本完成")

func _add_surface(mesh: ArrayMesh, quad: Array, texture_or_color):
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	vertices.append_array([quad[0], quad[1], quad[2], quad[3]])
	uvs.append_array([
		Vector2(0,1), Vector2(1,1),
		Vector2(1,0), Vector2(0,0)
	])

	indices.append_array([0,1,2, 0,2,3])

	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# 材质决定颜色/贴图
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# 禁用材质的光照影响
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


	if texture_or_color is Texture2D:
		mat.albedo_texture = texture_or_color
	else:
		mat.albedo_color = texture_or_color

	mesh.surface_set_material(mesh.get_surface_count() - 1, mat)

func open_book_cover_texture():
	if book.data_ref.book_cover_texture == "" or  book.data_ref.book_cover_texture == null:
		return
	book.open_book_cover()
	book_cover.visible = true
