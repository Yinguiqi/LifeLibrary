extends Control

@onready var books_container = $BooksContainer
@onready var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"
@onready var sidebar: PanelContainer = $Sidebar

func _ready() -> void:
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
