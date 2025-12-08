extends Control

@onready var texture_button = $TextureButton
@export var book_texture: Texture2D
@onready var books_container := get_parent()
@onready var default_texture_path = "res://icon.svg"
@export var book_id: String
@export var display_name: String
@export var texture_path: String
@export var rel_path: String
@export var scale_factor: String
var data_ref: RefCounted = null

const CONFIG_PATH := "user://config.ini"

func _ready():
		# 等一帧以确保节点已初始化
	await get_tree().process_frame
		# 如果 texture_path 有值，则动态加载纹理
	if data_ref.book_texture != "":
		book_texture = load_texture(data_ref.book_texture)
		apply_texture()
	if data_ref != null:
		apply_scale_from_data()
	

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
	print("加载纹理: ", book_texture)

	# 等一帧以确保节点已初始化
	await get_tree().process_frame

	var tex_size := book_texture.get_size()
	print(tex_size)
	texture_button.custom_minimum_size = tex_size
	texture_button.size = tex_size
	size = tex_size

	texture_button.stretch_mode = TextureButton.STRETCH_SCALE

## 应用 data_ref 中存储的 scale_factor 到场景节点的 scale 属性
func apply_scale_from_data():
	if data_ref == null:
		push_error("错误：尝试应用缩放时，data_ref 尚未设置。")
		return
	
	# 从数据对象中获取缩放值
	var scale_value = data_ref.scale_factor
	
	# 确保 scale_value 是 float 类型且有效
	if typeof(scale_value) != TYPE_FLOAT or scale_value <= 0:
		# 打印警告，并使用默认值 1.0
		push_warning("scale_factor 数据无效，使用默认值 1.0")
		scale_value = 1.0
	
	# 将获取到的 float 值应用到节点的 scale 属性上
	# Godot 节点的 scale 属性是 Vector2 类型
	self.scale = Vector2(scale_value, scale_value)
	
	print("书籍节点 '%s' 缩放已更新至: %f" % [name, scale_value])
