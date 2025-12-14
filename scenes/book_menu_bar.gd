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
	file_menu.id_pressed.connect(_on_file_menu_selected)
	edit_menu.id_pressed.connect(_on_file_menu_selected)
	

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
			get_tree().change_scene_to_file("res://scenes/set.tscn")

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
	# 创建窗口
	var window = Window.new()
	window.title = "搜索"
	window.size = Vector2(400, 150)
	window.unresizable = true
	
	# 创建内容容器
	var vbox = VBoxContainer.new()
	window.add_child(vbox)
	
	# 搜索输入行
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(line_edit)
	
	var search_btn = Button.new()
	search_btn.text = "搜索"
	hbox.add_child(search_btn)
	
		# 连接搜索按钮信号
	search_btn.pressed.connect(
		func():
			var search_results: Array = LibraryManager.get_books_by_name(line_edit.text,true)
			_redraw_book_shelf(search_results)
			pass # Replace with function body.
			window.hide()  # 搜索后关闭窗口
	)
	
	# 结果区域
	var results_label = Label.new()
	results_label.text = "结果将显示在这里"
	vbox.add_child(results_label)
	
	# 添加到场景并弹出
	get_tree().root.add_child(window)  # 添加到根节点
	window.popup_centered()
	
	# 关闭
	window.close_requested.connect(window.hide)  # 最简单的写法
	# 自动聚焦
	line_edit.grab_focus()
	 # Esc键关闭窗口
	line_edit.gui_input.connect(
		func(event):
			if event is InputEventKey:
				if event.keycode == KEY_ESCAPE and event.pressed:
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
