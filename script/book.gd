extends Control

const DRAG_THRESHOLD := 8.0
const CONFIG_PATH := "user://config.ini"

@onready var texture_button = $TextureButton
@onready var placeholder_spine = $PlaceholderSpine
@onready var book_cover: TextureRect = $BookCover
@onready var books_container := get_parent()


@export var book_texture: Texture2D
@export var book_cover_texture: Texture2D
var cover_on_left := false
var my_cover_width := 200.0  # 根据实际情况调整
var data_ref: Book = null
var has_spine_texture := false  # 是否有真实书脊图

# 拖拽相关变量
var is_dragging := false
var drag_offset := Vector2.ZERO  # 鼠标点击位置相对于书籍的偏移
var original_z_index := 0
# 拖拽候选与阈值（用于区分点击与拖拽）
var _drag_candidate := false
var _initial_mouse_pos := Vector2.ZERO
var book_scale_width : float


func _ready():
		# 等一帧以确保节点已初始化
	await get_tree().process_frame
	original_z_index = z_index
	if data_ref.book_texture != "":
		book_texture = load_texture(data_ref.book_texture)
		if book_texture:
			has_spine_texture = true
			_show_texture_button()
			apply_texture()
			apply_scale_from_data()
	if not has_spine_texture:
		_show_placeholder_spine()
		apply_placeholder_scale()
	if data_ref.book_cover_texture != "":
		book_cover_texture = load_texture(data_ref.book_cover_texture)
	
	# 连接输入事件（真实书脊和占位书脊都连同一套逻辑）
	if texture_button:
		texture_button.gui_input.connect(_on_spine_gui_input)
	if placeholder_spine:
		placeholder_spine.gui_input.connect(_on_spine_gui_input)
		
func load_texture(path: String) -> Texture2D:
	# 1. user:// 文件加载方式（Image）
	if path.begins_with("user://"):
		var img := Image.new()
		var err = img.load(path)
		if err == OK:
			return ImageTexture.create_from_image(img)
		else:
			print("user:// 图片加载失败: ", path)
			return null

	# 2. res:// 文件加载方式（ResourceLoader）
	var tex = ResourceLoader.load(path)
	if tex is Texture2D:
		return tex

	print("贴图加载失败: ", path)
	return null


# 设置纹理到按钮，并自动调整大小
func apply_texture():
	if book_texture == null:
		return

	texture_button.texture_normal = book_texture

	# 等一帧以确保节点已初始化
	await get_tree().process_frame

	var tex_size := book_texture.get_size()
	texture_button.custom_minimum_size = tex_size
	texture_button.size = tex_size
	size = tex_size

	texture_button.stretch_mode = TextureButton.STRETCH_SCALE


func apply_scale_from_data():
	if book_texture == null:
		push_error("错误：无法计算缩放，book_texture 尚未设置。")
		return
	
	# 获取纹理原始尺寸
	var tex_size = book_texture.get_size()
	
	# 计算缩放比例：目标高度673 ÷ 原始高度
	var target_height = LibraryManager.book_height
	var scale_value = target_height / tex_size.y
	
	# 确保缩放值有效
	if scale_value <= 0 or is_nan(scale_value):
		push_warning("计算出的缩放值无效: ", scale_value, "，使用默认值 1.0")
		scale_value = 1.0
	
	# 应用均匀缩放
	self.scale = Vector2(scale_value, scale_value)
	book_scale_width = tex_size.x * scale_value
	
	#设置书籍间隔
	self.position = Vector2(LibraryManager.book_x, 0)
	LibraryManager.book_x += book_scale_width
	LibraryManager.book_x += LibraryManager.book_spacing

# --- 占位书脊相关 ---
func _show_texture_button() -> void:
	texture_button.visible = true
	placeholder_spine.visible = false

func _show_placeholder_spine() -> void:
	texture_button.visible = false
	placeholder_spine.visible = true
	# 设置书名（竖排文字）
	if placeholder_spine and placeholder_spine.has_method("set_book_name"):
		placeholder_spine.set_book_name(data_ref.name if data_ref else "")

func apply_placeholder_scale() -> void:
	# 占位书脊：高度 = book_height，宽度 = 高度的 8%
	var target_height = LibraryManager.book_height
	var target_width = max(24.0, target_height * 0.08)
	
	# 设置占位书脊的尺寸
	if placeholder_spine and placeholder_spine.has_method("set_height"):
		placeholder_spine.set_height(target_height)
	
	size = Vector2(target_width, target_height)
	book_scale_width = target_width
	
	# 设置位置
	self.position = Vector2(LibraryManager.book_x, 0)
	LibraryManager.book_x += book_scale_width
	LibraryManager.book_x += LibraryManager.book_spacing
	
func open_book_cover():
	var tex_size = book_cover_texture.get_size()
	var scale_value = LibraryManager.book_height / tex_size.y / self.scale.x
	book_cover.size.y = LibraryManager.book_height / self.scale.x
	book_cover.size.x = tex_size.x * scale_value
	book_cover.texture = book_cover_texture
	# 书脊宽度：有纹理用纹理宽，没有就用占位书脊的宽
	var spine_width: float
	if has_spine_texture and book_texture:
		spine_width = book_texture.get_size().x
	else:
		spine_width = size.x
	book_cover.position.x = spine_width
	book_cover.visible = true
	books_container.on_book_expand(self, book_cover.size.x * self.scale.x)
	


func _on_spine_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 标记为拖拽候选（暂不拦截），等待鼠标移动判断是否为拖拽
			_drag_candidate = true
			_initial_mouse_pos = get_global_mouse_position()
		else:
			# 鼠标释放：如果已经在拖拽中则结束拖拽；否则为普通点击
			if is_dragging:
				is_dragging = false
				_drag_candidate = false
				books_container.set_book_dragging(self, false)
				z_index = original_z_index
				books_container.on_book_drag_end(self)
				get_viewport().set_input_as_handled()
			else:
				# 普通点击：打开书籍
				_drag_candidate = false
				_on_spine_clicked()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# 拖拽中不弹菜单
		if is_dragging or books_container.dragging_book != null:
			get_viewport().set_input_as_handled()
			return
		get_viewport().set_input_as_handled()
		_show_context_menu()

	elif event is InputEventMouseMotion:
		# 如果处于拖拽候选，且移动超过阈值，则真正开始拖拽
		if _drag_candidate and not is_dragging:
			var move_dist = get_global_mouse_position().distance_to(_initial_mouse_pos)
			if move_dist > DRAG_THRESHOLD:
				is_dragging = true
				_drag_candidate = false
				books_container.set_book_dragging(self, true)
				# 计算鼠标相对于书籍的偏移（使用本地鼠标位置）
				var local_mouse_pos = get_local_mouse_position()
				drag_offset = local_mouse_pos
				# 提高层级，确保拖拽的书在最上层
				z_index = 100
				# 记录初始位置
				books_container.on_book_drag_start(self)
				# 接受事件，防止传递给其他节点
				get_viewport().set_input_as_handled()
		# 如果正在拖拽，则处理移动
		elif is_dragging:
			var global_mouse_pos = get_global_mouse_position()
			var container_global_pos = books_container.global_position
			# 计算在容器坐标系中的位置（鼠标位置减去容器位置，再减去点击时的偏移）
			var new_x = global_mouse_pos.x - container_global_pos.x - drag_offset.x
			self.position.x = new_x
			# 通知容器检测是否需要交换
			books_container.check_swap_position(self)
			# 接受事件
			get_viewport().set_input_as_handled()

func _on_book_cover_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		books_container.on_book_collapse(self)
		book_cover.texture = null
		book_cover.visible = false
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
			# 判断封面当前在哪边
		if book_cover.position.x > 0:
			# 封面在右边 → 移到左边
			book_cover.position.x = -book_cover.size.x
			self.position.x += book_cover.size.x * self.scale.x
		else:
		# 封面在左边 → 移回右边
			book_cover.position.x = self.size.x
			self.position.x -= book_cover.size.x * self.scale.x

# --- 点击与右键菜单 ---
# 书脊点击（左键释放且未拖拽时调用）
func _on_spine_clicked() -> void:
	if data_ref == null or data_ref.rel_path == "":
		return
	var file_path := LibraryManager.base_path + data_ref.rel_path
	OS.shell_open(file_path)

# 弹出右键菜单（用全局的 UI/PopupMenu，保持样式一致）
func _show_context_menu() -> void:
	# 获取主场景里的全局 PopupMenu
	var main_node := get_tree().current_scene
	var menu := main_node.get_node("UI/PopupMenu")
	menu.clear()
	# 断开旧连接
	var connections = menu.id_pressed.get_connections()
	for conn in connections:
		menu.id_pressed.disconnect(conn.callable)
	menu.id_pressed.connect(_on_context_menu_pressed)
	
	menu.add_item(tr("book_edit_info"), 0)
	menu.add_item(tr("book_expand_cover"), 1)
	menu.add_item(tr("book_3d_viewer"), 2)
	menu.add_item(tr("book_open_folder"), 3)
	menu.add_item(tr("book_delete"), 4)
	menu.popup(Rect2(get_global_mouse_position(), Vector2.ZERO))

func _on_context_menu_pressed(id: int) -> void:
	match id:
		0:
			_edit_book()
		1:
			_expand_cover()
		2:
			_setup_3d_monitor()
		3:
			_open_book_folder()
		4:
			_delete_book()

func _edit_book() -> void:
	if data_ref == null:
		return
	var book_dict := {
		"book_id": data_ref.id,
		"name": data_ref.name,
		"author": data_ref.author,
		"rel_path": data_ref.rel_path,
		"book_texture": data_ref.book_texture,
		"book_cover_texture": data_ref.book_cover_texture,
		"introduction": data_ref.introduction,
		"group_name": data_ref.group_name
	}
	var window := preload("res://scenes/add_book_window.tscn").instantiate()
	add_child(window)
	window.load_book_data(book_dict)

func _expand_cover() -> void:
	if data_ref == null or data_ref.book_cover_texture == "":
		return
	open_book_cover()
	book_cover.visible = true

func _open_book_folder() -> void:
	if data_ref == null or data_ref.rel_path == "":
		return
	var file_path := LibraryManager.base_path + data_ref.rel_path
	var dir_path := file_path.get_base_dir()
	OS.shell_open(dir_path)

func _delete_book() -> void:
	if data_ref == null:
		return
	LibraryManager.delete_book_by_id(data_ref.id)
	LibraryManager.book_x -= book_scale_width
	LibraryManager.book_x -= LibraryManager.book_spacing
	books_container.remove_child(self)
	queue_free()
	books_container.is_dragging = false
	books_container.position.x = LibraryManager.books_container_x
	books_container._relayout_books()

func _setup_3d_monitor() -> void:
	# 3D 查看器逻辑暂时调用 texture_button 里的实现（通过节点路径找）
	# 后续可以把 3D 逻辑也移到这里
	if has_node("TextureButton") and $TextureButton.has_method("setup_3d_monitor"):
		$TextureButton.setup_3d_monitor()
