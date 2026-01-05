# BookMenuBar.gd
extends Control  # ← 注意：继承 Control，不是 MenuBar

@onready var books_container = $"../BooksContainer"
@onready var BookScene := preload("res://scenes/book.tscn")
@onready var AddBookWindow := preload("res://scenes/add_book_window.tscn")

@onready var file_menu: PopupMenu = $MenuBar/File
@onready var edit_menu: PopupMenu = $MenuBar/Edit
@onready var help_menu: PopupMenu = $MenuBar/Help
@onready var menu_bar: MenuBar = $MenuBar  # 引用实际的 MenuBar

var feedback_label: Label

func _ready():
	setup_menus()

func setup_menus():
	file_menu.name = "文件"
	edit_menu.name = "编辑"
	help_menu.name = "帮助"
	
	file_menu.add_item("新建书籍", 100)
	file_menu.add_item("退出", 110)
	
	edit_menu.add_item("搜索", 201)
	edit_menu.add_item("首选项", 210)
	
	help_menu.add_item("关于", 301)
	help_menu.add_item("教程", 302)
	help_menu.add_item("简易ps网站", 303)
	help_menu.add_item("闲鱼", 304)
	help_menu.add_item("日本二手网站", 305)
	
	file_menu.id_pressed.connect(_on_file_menu_selected)
	edit_menu.id_pressed.connect(_on_file_menu_selected)
	help_menu.id_pressed.connect(_on_file_menu_selected)
	

func _on_file_menu_selected(id: int) -> void:
	# 发射具体信号（方便主场景连接）
	match id:
		100: 
			var _add_book_window = AddBookWindow.instantiate()
			get_tree().root.add_child(_add_book_window)
		110:
			get_tree().quit()
		201:
			create_search_window()
		210:
			open_settings_window()
		301:
			about_the_game()
		302:
			OS.shell_open("https://milkyaw.online/2025/12/15/Life%20Library/")
		303:
			OS.shell_open("https://www.photopea.com/")
		304:
			OS.shell_open("https://www.goofish.com/")
		305:
			OS.shell_open("https://jp.mercari.com/search?keyword=")

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
		books_container.is_dragging = false
		books_container.velocity_x = 0
		var search_results = LibraryManager.get_books_by_name(line_edit.text, true)
		_redraw_book_shelf(search_results)
		window.hide()
	)

	window.close_requested.connect(func():
		window.hide()
		books_container.is_dragging = false
	)

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
		LibraryManager.book_x = 1000
		# 实例化场景
		var new_book_node = BookScene.instantiate()
		
		# 绑定数据对象到节点 (为了后续操作，如删除、编辑)
		new_book_node.data_ref = book_data_object 
		
		# 添加到容器
		books_container.add_child(new_book_node)
	print("书架过滤完成，显示书籍数量: ", books_to_display.size())

# 打开首选项功能
func open_settings_window():
	var window = Window.new()
	window.title = "设置"
	window.size = Vector2(500, 250)
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

	# === 基础路径标签 ===
	var path_label = Label.new()
	path_label.text = "基础路径设置:"
	path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(path_label)

	# === 基础路径输入行 ===
	var path_hbox = HBoxContainer.new()
	path_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(path_hbox)

	# 路径输入框
	var input = LineEdit.new()
	input.placeholder_text = "请输入基础路径"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(300, 36)
	path_hbox.add_child(input)

	# 路径保存按钮
	var save_path_btn = Button.new()
	save_path_btn.text = "保存路径"
	save_path_btn.custom_minimum_size = Vector2(100, 36)
	path_hbox.add_child(save_path_btn)

	# === 书籍高度设置 ===
	# 高度标签
	var height_label = Label.new()
	height_label.text = "书籍高度设置:"
	height_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(height_label)

	# 高度输入行
	var height_hbox = HBoxContainer.new()
	height_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(height_hbox)

	# 高度输入框
	var height_input = LineEdit.new()
	height_input.placeholder_text = "输入书籍高度 (0-5000)"
	height_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	height_input.custom_minimum_size = Vector2(300, 36)
	height_hbox.add_child(height_input)

	# 高度保存按钮
	var save_height_btn = Button.new()
	save_height_btn.text = "保存高度"
	save_height_btn.custom_minimum_size = Vector2(100, 36)
	height_hbox.add_child(save_height_btn)
	
	# === 书籍间隔设置 ===
	# 高度标签
	var spacing_label = Label.new()
	spacing_label.text = "书籍间隔设置:"
	spacing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vbox.add_child(spacing_label)

	# 高度输入行
	var spacing_hbox = HBoxContainer.new()
	spacing_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacing_hbox)

	# 高度输入框
	var spacing_input = LineEdit.new()
	spacing_input.placeholder_text = "输入书籍间隔 (0-200)"
	spacing_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacing_input.custom_minimum_size = Vector2(300, 36)
	spacing_hbox.add_child(spacing_input)

	# 高度保存按钮
	var save_spacing_btn = Button.new()
	save_spacing_btn.text = "保存间隔"
	save_spacing_btn.custom_minimum_size = Vector2(100, 36)
	spacing_hbox.add_child(save_spacing_btn)

	# === 反馈标签 ===（关键：这里创建Label实例）
	feedback_label = Label.new()
	feedback_label.add_theme_color_override("font_color", Color.GRAY)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(0, 24)  # 给点高度
	vbox.add_child(feedback_label)
	
	# === 加载现有配置 ===
	var cfg = ConfigFile.new()
	if cfg.load("user://config.ini") == OK:
		# 加载基础路径
		var saved_path = cfg.get_value("settings", "base_path", "")
		input.text = saved_path
		
		# 加载书籍高度，如果没有设置过，默认用673，书籍间隔同理
		var saved_height = cfg.get_value("settings", "book_height", 673.0)
		var saved_spacing = cfg.get_value("settings", "book_spacing", 20.0)
		height_input.text = str(saved_height)
		spacing_input.text = str(saved_spacing)

	# === 按钮连接 ===
	# 保存路径按钮
	save_path_btn.pressed.connect(func():
		var cfg_save = ConfigFile.new()
		cfg_save.load("user://config.ini")
		cfg_save.set_value("settings", "base_path", input.text)
		cfg_save.save("user://config.ini")
		
		show_feedback("基础路径已保存", Color.GREEN)
	)

	# 保存高度按钮 - 添加验证逻辑
	save_height_btn.pressed.connect(func():
		var height_text = height_input.text.strip_edges()
		
		# 验证输入是否为空
		if height_text.is_empty():
			show_feedback("请输入书籍高度", Color.RED)
			return
		
		# 验证是否为数字
		if not height_text.is_valid_float():
			show_feedback("请输入有效的数字", Color.RED)
			return
		
		# 转换为float并验证范围
		var height_value = float(height_text)
		if height_value < 0 or height_value > 5000:
			show_feedback("高度必须在0到5000之间", Color.RED)
			return
		
		# 保存到配置文件
		var cfg_save = ConfigFile.new()
		cfg_save.load("user://config.ini")
		cfg_save.set_value("settings", "book_height", height_value)
		cfg_save.save("user://config.ini")
		
		# 设置全局变量
		LibraryManager.book_height = height_value
		
		show_feedback("书籍高度已保存: " + str(height_value), Color.GREEN)
	)
	
	# 保存间隔按钮 - 添加验证逻辑
	save_spacing_btn.pressed.connect(func():
		var spacing_text = spacing_input.text.strip_edges()
		
		# 验证输入是否为空
		if spacing_text.is_empty():
			show_feedback("请输入书籍间隔", Color.RED)
			return
		
		# 验证是否为数字
		if not spacing_text.is_valid_float():
			show_feedback("请输入有效的数字", Color.RED)
			return
		
		# 转换为float并验证范围
		var spacing_value = float(spacing_text)
		if spacing_value < 0 or spacing_value > 200:
			show_feedback("间隔必须在0到200之间", Color.RED)
			return
		
		# 保存到配置文件
		var cfg_save = ConfigFile.new()
		cfg_save.load("user://config.ini")
		cfg_save.set_value("settings", "book_spacing", spacing_value)
		cfg_save.save("user://config.ini")
		
		# 设置全局变量
		LibraryManager.book_spacing = spacing_value
		
		show_feedback("书籍间隔已保存: " + str(spacing_value), Color.GREEN)
	)
	
	window.close_requested.connect(func():
			window.hide()
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	
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


func show_feedback(message: String, color: Color):
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", color)
   
	   # 3秒后清除反馈
	await get_tree().create_timer(3.0).timeout
	feedback_label.text = ""

func about_the_game():
	var window = Window.new()
	window.title = "关于"
	window.size = Vector2(500, 800)
	window.unresizable = false

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
	# ===== 使用VBoxContainer垂直排列 =====
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 标题
	var title_label = Label.new()
	title_label.text = "关于这个程序"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	# 分隔线
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# 内容
	var content_text = """
电子书架
版本：0.1.5
开发者：Milkyaw(棉花)


目前有的功能：书籍的增删查改，添加书籍在菜单栏文件里面、查找在菜单栏编辑里面，删和改对着书籍右键就能看到
		新建书籍必须要有书籍文件，什么版本都可以，反正我这里没有内置查看器，cbz的建议去下载calibre
		还有需要书脊图片，这个只能靠你自己从网上找了，我是从闲鱼等二手网上找图再用ps网站变换后截一个长方形
		封面图片可有可无，有的话可以使用展开封面的功能，对准书籍鼠标右键的菜单里有，再点一下封面就会消失
		对着封面按右键还会把封面放到书脊的左边、这个功能是考虑到很多单行本都是从右往左看的
		3d监看器目前只能实现一个长方体，本来这个软件是打算做出3d的，可惜我还没学过，以后可能有机会
		分类就在左边，分类名变动的逻辑还需要改一下
		有问题和需求可以在github提出
		https://github.com/Yinguiqi/LifeLibrary
		这软件基本上就是我用ai搞的，很乱，但能用
"""
	
	var content_label = Label.new()
	content_label.text = content_text
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(content_label)

	window.close_requested.connect(func():
		window.hide()
		books_container.is_dragging = false
	)
	
	# ===== 添加到场景 =====
	get_tree().root.add_child(window)
	window.popup_centered()
