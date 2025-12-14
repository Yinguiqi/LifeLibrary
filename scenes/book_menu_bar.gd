# BookMenuBar.gd
extends Control  # ← 注意：继承 Control，不是 MenuBar

@onready var file_menu: PopupMenu = $MenuBar/File
@onready var edit_menu: PopupMenu = $MenuBar/Edit
@onready var help_menu: PopupMenu = $MenuBar/Help
@onready var menu_bar: MenuBar = $MenuBar  # 引用实际的 MenuBar

func _ready():
	setup_menus()

func setup_menus():
	file_menu.name = "文件（F）"
	edit_menu.name = "编辑（E）"
	help_menu.name = "帮助（H）"
	
	file_menu.add_item("新建书籍", 100)
	file_menu.add_item("退出", 110)
	
	edit_menu.add_item("首选项", 201)
	file_menu.id_pressed.connect(_on_file_menu_selected)
	edit_menu.id_pressed.connect(_on_file_menu_selected)
	

func _on_file_menu_selected(id: int) -> void:
	# 发射具体信号（方便主场景连接）
	match id:
		100: 
			file_new_selected()
		110:
			get_tree().quit()
		201:
			get_tree().change_scene_to_file("res://scenes/set.tscn")

## 增加书籍
func file_new_selected() -> void:
	print(111)
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = BookData.base_path  # ← 指定打开的文件夹
	dialog.title = "选择一个文件"
	add_child(dialog)
	dialog.popup_centered()

	dialog.file_selected.connect(_add_book_on_file_selected)

# 把绝对路径改成相对路径并生成书籍且保存数据到JSON
func _add_book_on_file_selected(path: String):
	var pathx = get_relative_path(path)

	# 2. 保存到 JSON
	var texture_path = "res://assets/book_texture/1.png" 
	LibraryManager.add_new_book(pathx,texture_path)
	print("已保存到 JSON：", " → ", pathx)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# 把绝对路径改成相对路径的方法
func get_relative_path(abs_path: String) -> String:
	if not BookData.base_path.ends_with("/"):
		BookData.base_path += "/"

	# Godot 字符串处理
	if abs_path.begins_with(BookData.base_path):
		return abs_path.replace(BookData.base_path, "")
	return abs_path  # 不在 base_path 下就直接返回原路径
