# BookMenuBar.gd
extends Control  # ← 注意：继承 Control，不是 MenuBar

@onready var books_container = $"../BooksContainer"
@onready var BookScene := preload("res://scenes/book.tscn")

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
	
	edit_menu.add_item("搜索", 201)
	edit_menu.add_item("首选项", 210)
	
	help_menu.add_item("教程", 302)
	
	file_menu.id_pressed.connect(_on_file_menu_selected)
	edit_menu.id_pressed.connect(_on_file_menu_selected)
	help_menu.id_pressed.connect(_on_file_menu_selected)
	

func _on_file_menu_selected(id: int) -> void:
	# 发射具体信号（方便主场景连接）
	match id:
		100: 
			file_new_selected()
		110:
			get_tree().quit()
		201:
			create_search_window()
		210:
			open_settings_window()
			#get_tree().change_scene_to_file("res://scenes/set.tscn")
		302:
			OS.shell_open("https://milkyaw.online/2025/12/15/Life%20Library/")

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

func create_search_window():
	var window = Window.new()
	window.title = "搜索"
	window.size = Vector2(400, 150)
	window.unresizable = true

	# ===== 外层：边距容器 =====
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	window.add_child(margin)

	# 让 margin 撑满窗口
	margin.anchor_right = 1
	margin.anchor_bottom = 1

	# ===== 垂直布局 =====
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# ===== 水平布局 =====
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)

	# ===== 输入框 =====
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "请输入书名"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(0, 36)
	hbox.add_child(line_edit)

	# ===== 搜索按钮 =====
	var search_btn = Button.new()
	search_btn.text = "搜索"
	search_btn.custom_minimum_size = Vector2(80, 36)
	hbox.add_child(search_btn)

	# ===== 信号 =====
	search_btn.pressed.connect(func():
		var search_results = LibraryManager.get_books_by_name(line_edit.text, true)
		_redraw_book_shelf(search_results)
		window.hide()
	)

	window.close_requested.connect(window.hide)

	# ===== 添加到场景 =====
	get_tree().root.add_child(window)
	window.popup_centered()

	line_edit.grab_focus()

	line_edit.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			window.hide()
	)

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
		
		# 计算位置
		var new_x = i * 100.0 # 假设间隔 100 像素
		new_book_node.position = Vector2(new_x, 0)
		
		# 添加到容器
		books_container.add_child(new_book_node)
	
	print("书架过滤完成，显示书籍数量: ", books_to_display.size())

# 打开首选项功能
func open_settings_window():
	var window = Window.new()
	window.title = "设置"
	window.size = Vector2(500, 200)
	window.unresizable = true
	
	# 边距容器
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	window.add_child(margin)
	
	# 垂直布局
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	# === 标签 ===
	var label = Label.new()
	label.text = "基础路径设置:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(label)
	
	# === 输入框和按钮在同一行 ===
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # 撑满父容器
	vbox.add_child(hbox)

	# 输入框 - 让它占据大部分空间
	var input = LineEdit.new()
	input.placeholder_text = "请输入基础路径"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # 关键：水平扩展
	input.size_flags_stretch_ratio = 3.0  # 占据更多比例（可选）
	input.custom_minimum_size = Vector2(300, 36)  # 设置最小宽度
	hbox.add_child(input)

	# 按钮 - 固定宽度在右边
	var save_btn = Button.new()
	save_btn.text = "保存"
	save_btn.custom_minimum_size = Vector2(80, 36)
	hbox.add_child(save_btn)
	
	# === 加载现有配置 ===
	var cfg = ConfigFile.new()
	if cfg.load("user://config.ini") == OK:
		var saved_path = cfg.get_value("settings", "base_path", "")
		input.text = saved_path

	
	save_btn.pressed.connect(func():
		# 保存配置
		var cfg_save = ConfigFile.new()
		cfg_save.load("user://config.ini")
		cfg_save.set_value("settings", "base_path", input.text)
		cfg_save.save("user://config.ini")
		
		# 关闭窗口
		window.hide()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		
		# 可选：通知主场景配置已更新
		emit_signal("settings_updated")
	)
	
	window.close_requested.connect(window.hide)
	
	# === 添加到场景树 ===
	get_tree().root.add_child(window)
	window.popup_centered()
	
	# 自动聚焦到输入框
	input.grab_focus()
	
	# ESC键关闭
	input.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			window.hide()
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	
	return window
