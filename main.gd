extends Control

@onready var books_container = $BooksContainer
@onready var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"

func _ready() -> void:
	LibraryManager.book_x = 500
	check_base_path()
	LibraryManager.load_book_height_from_config()
	load_books_from_json()
	books_container.position.x = LibraryManager.books_container_x
	
	
	
# 检查是否存在base_path路径
func check_base_path():
	if BookData.base_path != null :
		var cfg := ConfigFile.new()
		cfg.load(CONFIG_PATH)
		var base_path = cfg.get_value("settings", "base_path", "")
		BookData.base_path = base_path

func load_books_from_json():
	# 1. 检查文件是否存在
	if not FileAccess.file_exists(JSON_PATH):
		print("JSON 文件不存在")
		return

	# 2. 读取并解析 JSON
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error != OK:
		print("JSON 解析失败: ", json.get_error_message())
		return

	# 获取数据数组 (Array[Dictionary])
	var books_data: Array = json.data 
	
	if books_data.is_empty():
		print("JSON 数据为空")
		return

	# 3. 排序 (保持你原来的逻辑：按 id 里的数字排序)
	# 假设 id 格式依然是 "Book4", "Book10"
	books_data.sort_custom(func(a, b):
		var id_a = int(str(a.get("id", "0")).trim_prefix("Book"))
		var id_b = int(str(b.get("id", "0")).trim_prefix("Book"))
		return id_a < id_b
	)

	# 4. 遍历数组并创建场景
	# 我们在这里引入 index (i)，方便计算位置，不用去读取上一个子节点了
	for i in range(books_data.size()):
		var data = books_data[i]
		
		# 调用专门的创建函数
		_create_book_node_from_data(data, i)

	
# --- 专门用于从数据创建节点的函数 ---
# 参数 data: 包含书本信息的字典
# 参数 index: 当前是第几本书 (用于计算位置)
func _create_book_node_from_data(data: Dictionary, index: int):
	var rel_path = data.get("rel_path", "")
	if rel_path == "":
		return

	# 1. 实例化
	var new_book = BookScene.instantiate()
	
	# 2. 赋值属性 (直接从字典取值)
	var book_data_object = LibraryManager.create_book_object_from_dict(data)
	new_book.data_ref = book_data_object

	# 4. 添加到容器
	books_container.add_child(new_book)

# 关闭3d监看器按钮
func _on_close_3DMonitor_button_pressed() -> void:
	$PanelContainer.visible = false
	
