extends Control


var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"
@onready var sidebar: PanelContainer = $Sidebar
@onready var books_container = $BooksContainer

func _ready() -> void:
	load_window_state()
	LibraryManager.book_x = 500
	check_base_path()
	LibraryManager.load_book_height_from_config()
	load_books_from_json()

	
# 检查是否存在base_path路径
func check_base_path():
	if BookData.base_path != null :
		var cfg := ConfigFile.new()
		cfg.load(CONFIG_PATH)
		var base_path = cfg.get_value("settings", "base_path", "")
		BookData.base_path = base_path

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
	print("111")
	config.set_value("window", "width", window_size.x)
	config.set_value("window", "height", window_size.y)
	config.set_value("window", "x", pos.x)
	config.set_value("window", "y", pos.y)

	config.save(CONFIG_PATH)

func load_window_state():
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	var window := get_window()
	print("222")
	var w = config.get_value("window", "width", 1280)
	var h = config.get_value("window", "height", 720)
	var x = config.get_value("window", "x", 100)
	var y = config.get_value("window", "y", 100)

	window.size = Vector2i(w, h)
	window.position = Vector2i(x, y)
