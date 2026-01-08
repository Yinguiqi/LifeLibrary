extends Control

@onready var texture_button = $TextureButton
@onready var book_cover: TextureRect = $BookCover

@export var book_texture: Texture2D
@export var book_cover_texture: Texture2D
@onready var books_container := get_parent()
@onready var default_texture_path = "res://icon.svg"
@onready var book_scale_width : float
var cover_on_left := false
var my_cover_width := 200.0  # 根据实际情况调整
var data_ref: RefCounted = null

# 拖拽相关变量
var is_dragging := false
var drag_offset := Vector2.ZERO  # 鼠标点击位置相对于书籍的偏移
var original_z_index := 0

const CONFIG_PATH := "user://config.ini"


func _ready():
		# 等一帧以确保节点已初始化
	await get_tree().process_frame
	original_z_index = z_index
	if data_ref.book_texture != "":
		book_texture = load_texture(data_ref.book_texture)
		apply_texture()
		apply_scale_from_data()
	if data_ref.book_cover_texture != "":
		book_cover_texture = load_texture(data_ref.book_cover_texture)
	
	# 连接 TextureButton 的输入事件
	if texture_button:
		texture_button.gui_input.connect(_on_texture_button_gui_input)
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
	
func open_book_cover():
	var tex_size = book_cover_texture.get_size()
	var scale_value = LibraryManager.book_height / tex_size.y / self.scale.x
	book_cover.size.y = LibraryManager.book_height / self.scale.x
	book_cover.size.x = tex_size.x * scale_value
	book_cover.texture = book_cover_texture
	book_cover.position.x = book_texture.get_size().x
	books_container.on_book_expand(self, book_cover.size.x * self.scale.x)
	


func _on_texture_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 开始拖拽
			is_dragging = true
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
		else:
			# 结束拖拽
			if is_dragging:
				is_dragging = false
				books_container.set_book_dragging(self, false)
				z_index = original_z_index
				books_container.on_book_drag_end(self)
				get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion and is_dragging:
		# 拖拽移动：书籍跟随鼠标
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
