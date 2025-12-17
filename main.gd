extends Control

@onready var books_container = $VBoxContainer/BooksContainer
@onready var BookScene := preload("res://scenes/book.tscn")
const CONFIG_PATH := "user://config.ini"
const JSON_PATH = "user://books_data.json"
@onready var find_book: LineEdit = $FindBookInput

var tray_id: int = -1
var tray_menu: PopupMenu
var is_window_visible: bool = true  # 跟踪窗口状态

var is_dragging := false
var last_mouse_x := 0.0
var velocity_x := 0.0

func _ready() -> void:
	check_base_path()
	load_books_from_json()
	_setup_tray()
	get_tree().set_auto_accept_quit(false)
	
# 检查是否存在base_path路径
func check_base_path():
	if BookData.base_path != null :
		var cfg := ConfigFile.new()
		cfg.load(CONFIG_PATH)
		var base_path = cfg.get_value("settings", "base_path", "")
		BookData.base_path = base_path

# 
func _unhandled_input(event):
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
	books_container.position.x = clamp(books_container.position.x, -100*LibraryManager._books.size()+1000, 200)


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
	new_book.scale_factor = str(data.get("scale_factor", ""))
	new_book.rel_path = rel_path
	var book_data_object = LibraryManager.create_book_object_from_dict(data)
	new_book.data_ref = book_data_object
	# 3. 计算位置 (更加稳定：直接基于它是第几个)
	# 如果你希望第一本在 0，第二本在 100，第三本在 200
	var new_x = index * 100.0
	new_book.position = Vector2(new_x, 0)

	# 4. 添加到容器
	books_container.add_child(new_book)

# 关闭3d监看器按钮
func _on_close_3DMonitor_button_pressed() -> void:
	$PanelContainer.visible = false
	
func _setup_tray():
	# 创建托盘菜单
	tray_menu = PopupMenu.new()
	add_child(tray_menu)
	
	# 添加菜单项
	tray_menu.add_item("退出", 0)
	tray_menu.id_pressed.connect(_on_tray_menu_pressed)
	
	# 创建系统托盘图标
	tray_id = DisplayServer.create_status_indicator(
		load("res://icon.svg"),  # 确保这个图标存在
		"我的书架",
		_on_tray_mouse
	)

# 你的托盘点击逻辑调用这个函数
func _on_tray_menu_pressed(id):
	match id:
		0: # 退出
			get_tree().quit() # 这才是真退出
	# 注意：不要在初始化时隐藏窗口，让它保持可见

func _on_tray_mouse(button: MouseButton, _click_pos: Vector2i):
	if button == MOUSE_BUTTON_RIGHT:
		var global_mouse = DisplayServer.mouse_get_position()
		# 原有逻辑
		tray_menu.position = global_mouse
		tray_menu.popup()
		
	elif button == MOUSE_BUTTON_LEFT:
		# 左键点击切换窗口显示/隐藏
		_set_window_visible(true)
		
func _set_window_visible(_show: bool):
	var window = get_window()
	is_window_visible = _show
	
	if _show:
		# 使用 call_deferred 延迟显示操作
		window.call_deferred("show")
		
		# 其他非敏感操作可以继续正常执行
		if window.mode == Window.MODE_MINIMIZED:
			window.mode = Window.MODE_WINDOWED
			
		window.grab_focus()
	else:
		# 【关键】使用 call_deferred 延迟隐藏操作
		window.call_deferred("set_mode", Window.MODE_MINIMIZED)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# 阻止 Godot 默认退出
		get_tree().set_auto_accept_quit(false) 
		
		# 调用延迟隐藏
		_set_window_visible(false)
