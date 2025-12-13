extends TextureButton

@onready var menu := $"../../../../UI/PopupMenu"
@onready var book := $".."
@export var book_id : String
const CONFIG_PATH := "user://config.ini"
const MONITOR_SCENE = preload("res://scenes/3DMonitor.tscn")
@onready var sub_viewport = $"../../../../PanelContainer/SubViewportContainer/SubViewport"
@onready var panel_container = $"../../../../PanelContainer"

# 左键按钮
func _on_pressed() -> void:
	await get_tree().process_frame
	var pdf_path = BookData.base_path + book.data_ref.rel_path
##	var pdf_path = "D:/资源/文章类/电子书/专业书籍/游戏设计艺术（第3版）[[美] Jesse Schell](1).pdf"
	OS.shell_open(pdf_path)

# 右键按钮
func _on_gui_input(event: InputEvent) -> void:
	# 检测右键
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		accept_event()
		print("处理逻辑的实体名称: ", self.name)
		# 1. 【关键步骤】先清空旧的选项！
		menu.clear() 
		# ==========================================
		# 2. 【关键修复】断开所有旧的信号连接
		# ==========================================
		# 获取连在 id_pressed 上的所有连接信息
		var connections = menu.id_pressed.get_connections()
		for conn in connections:
			# 断开它们！
			menu.id_pressed.disconnect(conn.callable)
		menu.id_pressed.connect(_on_menu_pressed)
		# 2. 然后再添加本次需要的选项
		menu.add_item("编辑书籍配置", 0)
		menu.add_item("设置书脊", 1)
		menu.add_item("设置封面", 2)
		menu.add_item("删除书籍", 3)
		menu.add_item("3d监看器", 4)
		menu.add_item("打开所在文件夹", 5)
		# 在弹出菜单前设置当前书籍ID
		LibraryManager.current_book_data = book.data_ref
		menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))

# 菜单选择逻辑
func _on_menu_pressed(id: int) -> void:
	match id:
		0:
			get_tree().call_deferred("change_scene_to_file", "res://scenes/book_settings.tscn")
		1:
			_on_book_texture_pressed()
		2:
			_on_book_cover_texture_pressed()
		3:
			delete_book_by_id()
		4:
			setup_3d_monitor()
		5:
			open_book_of_folder()

func _on_book_texture_pressed() -> void:
	choose_texture("user://book_textures/")

func _on_book_cover_texture_pressed() -> void:
	choose_texture("user://book_cover_textures/")

func choose_texture(target_folder: String) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = BookData.base_path
	dialog.file_selected.connect(func(path):
		var file = path.get_file()
		DirAccess.make_dir_recursive_absolute(target_folder)
		var target = target_folder + file
		var err = copy_file(path, target)
		if err != OK:
			print("复制失败: ", err)
		else:
			LibraryManager.update_book_info(book.book_id, book.name, book.rel_path, target, target,book.scale_factor)
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
	
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
	LibraryManager.delete_book_by_id(LibraryManager.current_book_data.id)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func open_book_of_folder():
	var path = BookData.base_path + book.data_ref.rel_path
	var dir_path = path.get_base_dir()
##	var pdf_path = "D:/资源/文章类/电子书/专业书籍/游戏设计艺术（第3版）[[美] Jesse Schell](1).pdf"
	OS.shell_open(dir_path)

func setup_3d_monitor():
	# 判断是否为空
	if book.data_ref.book_cover_texture == "" or book.data_ref.book_cover_texture == null:
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
