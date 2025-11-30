extends Button

const CONFIG_PATH := "user://config.ini"
@onready var main := $".."

func _on_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = BookData.base_path  # ← 指定打开的文件夹
	dialog.title = "选择一个文件"
	add_child(dialog)
	dialog.popup_centered()

	dialog.file_selected.connect(_on_file_selected)

# 把绝对路径改成相对路径并生成书籍且保存数据到ini
func _on_file_selected(path: String):
	var pathx = get_relative_path(path)
	print("相对路径: ", pathx)
	# 1. 创建并排列新书
	var new_book = main.create_new_book(pathx)

	# 2. 保存到 INI
	save_book_to_config(new_book.book_id, pathx)
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# 保存数据到ini
func save_book_to_config(book_id: String, rel_pathx: String):
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)

	# 写入到 [books] 分组
	config.set_value(book_id,"id", book_id)
	var book_name = rel_pathx.get_file().get_basename()
	config.set_value(book_id,"name", book_name)
	config.set_value(book_id,"rel_path", rel_pathx)
	config.set_value(book_id,"book_texture", "res://assets/book_texture/1.png")

	config.save(CONFIG_PATH)
	print("已保存到 INI：", book_id, " → ", rel_pathx)

# 把绝对路径改成相对路径的方法
func get_relative_path(abs_path: String) -> String:
	if not BookData.base_path.ends_with("/"):
		BookData.base_path += "/"

	# Godot 字符串处理
	if abs_path.begins_with(BookData.base_path):
		return abs_path.replace(BookData.base_path, "")
	return abs_path  # 不在 base_path 下就直接返回原路径
