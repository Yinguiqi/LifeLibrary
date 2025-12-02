extends TextureButton

@onready var menu := $"../../../UI/PopupMenu"
@onready var book := $".."
@export var book_id : String
const CONFIG_PATH := "user://config.ini"

# 左键按钮
func _on_pressed() -> void:
	await get_tree().process_frame
	var pdf_path = BookData.base_path + book.rel_path
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
		menu.add_item("删除书籍", 2)
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
			delete_book_by_id()

# 弹窗选择书脊
func _on_book_texture_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = BookData.base_path  # ← 指定打开的文件夹
	dialog.title = "选择一个文件"
	# 当文件被选择后，执行逻辑，然后销毁 dialog
	dialog.file_selected.connect(_handle_file_selection.bind(dialog))
	# 当用户点击取消或关闭窗口时，也必须销毁 dialog
	dialog.canceled.connect(dialog.queue_free)
	
	add_child(dialog)
	dialog.popup_centered()
	
# 书脊图片复制user文件夹里，且改变书籍book_texture路径
func _handle_file_selection(path: String, dialog: FileDialog) -> void:
	# 1. 定义目标路径：文件将被复制到 user:// 目录
	# 为了防止文件名冲突，我们使用文件名（带扩展名）作为目标文件名
	var file_name = path.get_file()
	var target_path = "user://book_textures/" + file_name
	# 确保目标目录存在（user://book_textures/）
	var dir = DirAccess.open("user://")
	if dir:
		dir.make_dir_recursive("book_textures")
	# 2. 执行文件复制操作
	# ----------------------------------------------------
	# copy_file 函数：从源路径复制到目标路径
	var error = copy_file(path, target_path) 
	# ----------------------------------------------------
	if error != OK:
		# 如果复制失败，打印错误并退出
		print("错误：文件复制失败！错误码: ", error)
		# 在 Godot 4 中，你可以使用 Error.get_error_string(error) 来获取更友好的错误信息
		dialog.queue_free()
		return
	# 3. 更新 BookData
	# 假设你希望 BookData.book_texture_path 记录的是这个新复制文件的路径
	LibraryManager.update_book_info(book.book_id, book.name ,book.rel_path, target_path)
	print("文件复制成功！新路径已设置为: ", target_path)
	# 4. 销毁 FileDialog
	dialog.queue_free()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

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
	
	
