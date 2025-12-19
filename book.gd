extends Control

@onready var texture_button = $TextureButton
@export var book_texture: Texture2D
@export var book_cover_texture: Texture2D
@onready var books_container := get_parent()
@onready var default_texture_path = "res://icon.svg"
@export var book_id: String
@export var display_name: String
@export var texture_path: String
@export var rel_path: String
var data_ref: RefCounted = null

const CONFIG_PATH := "user://config.ini"

func _ready():
		# 等一帧以确保节点已初始化
	await get_tree().process_frame
		# 如果 texture_path 有值，则动态加载纹理
	if data_ref.book_texture != "":
		book_texture = load_texture(data_ref.book_texture)
		apply_texture()
		apply_scale_from_data()
	if data_ref.book_cover_texture != "":
		book_cover_texture = load_texture(data_ref.book_cover_texture)
	
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

# 500高度
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
