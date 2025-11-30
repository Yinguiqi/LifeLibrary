extends Control

@onready var books_container = $BooksContainer
@onready var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"

var is_dragging := false
var last_mouse_x := 0.0
var velocity_x := 0.0

func _ready() -> void:
	check_base_path()
	load_books_from_config()

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
	var book_scene = preload("res://scenes/book.tscn")

	# 第一步：实例化 book
	var new_book = book_scene.instantiate()

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
