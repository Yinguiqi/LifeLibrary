extends Control

@onready var books_container = $BooksContainer
@onready var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"
@onready var find_book: LineEdit = $FindBookInput

var is_dragging := false
var last_mouse_x := 0.0
var velocity_x := 0.0

func _ready() -> void:
	check_base_path()
#	load_books_from_config()
	load_books_from_json()


# 检查是否存在base_path路径
func check_base_path():
	if BookData.base_path != null :
		var cfg := ConfigFile.new()
		cfg.load(CONFIG_PATH)
		var base_path = cfg.get_value("settings", "base_path", "")
		BookData.base_path = base_path

# 
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			last_mouse_x = event.position.x
			velocity_x = 0.0
		else:
			is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - last_mouse_x
		books_container.position.x += delta_x
		velocity_x = delta_x
		last_mouse_x = event.position.x

func _process(delta):
	if not is_dragging:
		books_container.position.x += velocity_x
		velocity_x *= 0.9  # 惯性阻尼（越小停得越快）
	books_container.position.x = clamp(books_container.position.x, 50, 700)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/set.tscn")
	
func load_books_from_config():
	var config := ConfigFile.new()
	var err = config.load(CONFIG_PATH)

	if err != OK:
		print("没有找到配置文件或读取失败")
		return

	# ① 获取 ini 里所有 section 名称
	var sections = config.get_sections()  # PackedStringArray

	# ② 过滤出 Book 开头的 sections
	var book_sections: Array = []
	for sec in sections:
		if sec.begins_with("Book"):
			book_sections.append(sec)

	if book_sections.is_empty():
		print("没有找到任何书籍条目")
		return

	# ③ 按 Book 后面的数字排序（Book1 < Book2 < Book10）
	book_sections.sort_custom(func(a, b):
		return int(a.substr(4)) < int(b.substr(4))
	)
	print(book_sections)
	# ④ 遍历所有书籍 section，并创建场景
	for sec in book_sections:
		var rel_path = config.get_value(sec, "rel_path", "")
		if rel_path == "":
			continue

		# 从 ini 获取所有字段
		var book_id = config.get_value(sec, "id", "")
		var book_name = config.get_value(sec, "name", "")
		var book_texture = config.get_value(sec, "book_texture", "")

		# 创建书籍节点（你自己的方法）
		var book := BookScene.instantiate()
		var new_book = create_new_book(rel_path)

		# 覆盖生成默认名字，保持与 INI 一致
		new_book.name = sec

		# 给书设置额外属性（如果你书的脚本里有对应变量）
		new_book.book_id = book_id
		new_book.display_name = book_name
		new_book.texture_path = book_texture
		new_book.rel_path = rel_path


func create_new_book(path: String):
	# 第一步：实例化 book
	var new_book = BookScene.instantiate()

	# 第二步：计算新书的名称
	# 获取当前已有多少本书（只统计名字以 Book 开头的）
	var count := 0
	for child in books_container.get_children():
		if child.name.begins_with("Book"):
			count += 1

	new_book.book_id = "Book%s" % (count + 1)

	# 第三步：计算 position.x = 上一本书的位置 + 100
	var new_x := 0.0
	if count > 0:
		var last_book := books_container.get_node("Book%s" % count)
		new_x = last_book.position.x + 100

	new_book.position = Vector2(new_x, 0)
	new_book.rel_path = path

	# 第四步：加入到 BooksContainer
	books_container.add_child(new_book)
	return new_book

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
	new_book.name = data.get("id", "BookNode") # 节点名
	new_book.book_id = data.get("id", "")
	new_book.display_name = data.get("name", "")
	new_book.texture_path = data.get("book_texture", "")
	new_book.rel_path = rel_path
	var book_data_object = LibraryManager.create_book_object_from_dict(data)
	new_book.data_ref = book_data_object
	# 3. 计算位置 (更加稳定：直接基于它是第几个)
	# 如果你希望第一本在 0，第二本在 100，第三本在 200
	var new_x = index * 100.0
	new_book.position = Vector2(new_x, 0)

	# 4. 添加到容器
	books_container.add_child(new_book)

## 搜索图书
func _on_find_book_pressed() -> void:
	var search_results: Array = LibraryManager.get_books_by_name(find_book.text,true)
	# 3. 更新 UI: 清空并重绘书架
	_redraw_book_shelf(search_results)
	pass # Replace with function body.

## 清空 books_container 并根据传入的列表重绘书籍节点
func _redraw_book_shelf(books_to_display: Array):
	
	# 1. 清空现有书架：释放所有子节点
	for child in books_container.get_children():
		child.queue_free()

	# 2. 遍历结果并重新创建场景节点
	for i in range(books_to_display.size()):
		var book_data_object = books_to_display[i] # 这是一个 BookData 对象
		
		# 实例化场景
		var new_book_node = BookScene.instantiate()
		
		# 绑定数据对象到节点 (为了后续操作，如删除、编辑)
		new_book_node.data_ref = book_data_object 
		
		# 赋值 UI 属性
		new_book_node.name = book_data_object.id # 设置节点名
		new_book_node.rel_path = book_data_object.rel_path
		new_book_node.texture_path = book_data_object.book_texture
		# ... 赋值其他显示相关的属性 ...
		
		# 计算位置
		var new_x = i * 100.0 # 假设间隔 100 像素
		new_book_node.position = Vector2(new_x, 0)
		
		# 添加到容器
		books_container.add_child(new_book_node)
	
	print("书架过滤完成，显示书籍数量: ", books_to_display.size())
