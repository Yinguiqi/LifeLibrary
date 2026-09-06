extends Control


var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"
@onready var sidebar: PanelContainer = $Sidebar
@onready var books_container = $BooksContainer

func _ready() -> void:
	LibraryManager.book_x = 500
	check_base_path()
	LibraryManager.load_book_height_from_config()
	load_books_from_json()
	load_window_state()
	# 监听窗口文件拖拽事件
	var window := get_window()
	print("[拖拽调试] 连接 files_dropped 信号")
	window.files_dropped.connect(_on_files_dropped)
	
# 检查是否存在base_path路径
func check_base_path():
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)
	var path = cfg.get_value("settings", "base_path", "")
	LibraryManager.base_path = path
	if not LibraryManager.base_path.is_empty() and not LibraryManager.base_path.ends_with("/"):
		LibraryManager.base_path += "/"

func load_books_from_json():
	# 使用 LibraryManager 已加载的内存数据，确保 UI 节点和 _books 引用同一个对象
	var books = LibraryManager.get_all_books()
	if books.is_empty():
		print("没有书籍数据可加载")
		return

	# 遍历内存中的书籍对象并创建 UI 节点
	for book_obj in books:
		var new_book = BookScene.instantiate()
		new_book.data_ref = book_obj  # 直接使用 LibraryManager._books 中的对象
		books_container.add_child(new_book)

# --- 拖拽文件创建书籍 ---
func _on_files_dropped(files: PackedStringArray) -> void:
	print("[拖拽调试] 收到 files_dropped 信号，文件数量: ", files.size())
	for f in files:
		print("[拖拽调试]   - ", f)
	
	# 如果没有设置 base_path，提示一下（静默跳过也行）
	if LibraryManager.base_path.is_empty():
		print("[拖拽调试] 失败：base_path 为空")
		print("拖拽失败：未设置 base_path，请先在首选项中设置书籍根目录")
		return

	var added_count: int = 0
	for file_path in files:
		# 只处理文件，跳过文件夹
		if not FileAccess.file_exists(file_path):
			continue
		# 跳过图片文件（那些应该是书脊/封面，不是书籍本身）
		var ext: String = file_path.get_extension().to_lower()
		if ext in ["png", "jpg", "jpeg", "bmp", "webp", "gif"]:
			continue
		
		if _add_book_from_file(file_path):
			added_count += 1
	
	if added_count > 0:
		print("拖拽添加完成，新增 %d 本书" % added_count)
		# 刷新当前分类视图
		sidebar._get_books_by_group(LibraryManager.current_selected_group)

func _add_book_from_file(abs_path: String) -> bool:
	# 计算相对路径
	var rel_path: String = abs_path
	if abs_path.begins_with(LibraryManager.base_path):
		rel_path = abs_path.replace(LibraryManager.base_path, "")
	else:
		# 文件不在 base_path 下，复制过去
		var file_name: String = abs_path.get_file()
		var dst_path: String = LibraryManager.base_path + file_name
		# 处理重名
		var i: int = 1
		while FileAccess.file_exists(dst_path):
			var base_name: String = file_name.get_basename()
			var ext: String = file_name.get_extension()
			dst_path = "%s%s_%d.%s" % [LibraryManager.base_path, base_name, i, ext]
			i += 1
		
		if _copy_file(abs_path, dst_path) != OK:
			print("复制文件失败: ", abs_path)
			return false
		rel_path = dst_path.replace(LibraryManager.base_path, "")
	
	# 书名用文件名（不带后缀）
	var book_name: String = abs_path.get_file().get_basename()
	
	# 创建书籍（书脊图和封面图留空，用占位显示）
	var new_book: Book = LibraryManager.add_new_book(rel_path, "", book_name, "", "", "", "")
	return new_book != null

func _copy_file(src_path: String, dst_path: String) -> int:
	var src = FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		return ERR_CANT_OPEN
	var dst = FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		return ERR_CANT_OPEN
	dst.store_buffer(src.get_buffer(src.get_length()))
	return OK
# 关闭3d监看器按钮
func _on_close_3DMonitor_button_pressed() -> void:
	$PanelContainer.visible = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_window_state()
		get_tree().quit()
		
func save_window_state():
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	var window := get_window()
	var window_size := window.size
	var pos := window.position
	config.set_value("window", "width", window_size.x)
	config.set_value("window", "height", window_size.y)
	config.set_value("window", "x", pos.x)
	config.set_value("window", "y", pos.y)
	config.set_value("window", "category", LibraryManager.current_selected_group)

	config.save(CONFIG_PATH)

func load_window_state():
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	var window := get_window()
	var w = config.get_value("window", "width", 1280)
	var h = config.get_value("window", "height", 720)
	var x = config.get_value("window", "x", 100)
	var y = config.get_value("window", "y", 100)
	LibraryManager.current_selected_group = config.get_value("window", "category", "")
	sidebar._get_books_by_group(LibraryManager.current_selected_group)
	window.size = Vector2i(w, h)
	window.position = Vector2i(x, y)
