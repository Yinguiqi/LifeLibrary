extends PanelContainer

@onready var label: Label = $VBoxContainer/Label
@onready var vbox: VBoxContainer = $VBoxContainer

@onready var books_container: Control = $"../BooksContainer"
@onready var BookScene := preload("res://scenes/book.tscn")
@onready var GroupManager := preload("res://scenes/group_manager.tscn")

var group_manager: Node = null

# 书脊颜色池（和 placeholder_spine 一致）
var spine_colors: Array[Color] = [
	Color(0.788, 0.471, 0.239),	# 橙棕
	Color(0.545, 0.235, 0.184),	# 深红棕
	Color(0.282, 0.459, 0.655),	# 深蓝
	Color(0.392, 0.529, 0.333),	# 深绿
	Color(0.522, 0.357, 0.620),	# 紫色
	Color(0.835, 0.733, 0.459),	# 米黄
	Color(0.443, 0.443, 0.443),	# 深灰
	Color(0.702, 0.302, 0.302),	# 酒红
]

# 当前选中的按钮节点引用
var current_selected_button: Control = null

func _ready() -> void:
	# 把 AllBook 按钮替换成书脊风格的，保持视觉统一
	_replace_all_book_with_spine_style()
	load_groups()

func load_groups() -> void:
	# 先清除所有现有的分组按钮
	clear_all_group_buttons()
	
	var cfg = ConfigFile.new()
	if cfg.load("user://config.ini") == OK and cfg.has_section("group"):
		var keys = cfg.get_section_keys("group")
		keys.reverse()
		for key in keys:
			var group = cfg.get_value("group", key)
			add_group_button(group)
	# 加载后刷新选中状态
	_refresh_selected_state()

# 替换 AllBook 按钮为书脊风格
func _replace_all_book_with_spine_style() -> void:
	var old_btn: Button = $VBoxContainer/AllBook
	var index: int = old_btn.get_index()
	
	# 创建新书脊风格按钮
	var btn := Control.new()
	btn.name = "AllBook"
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.set_meta("group_name", "")  # 空字符串代表全部
	btn.set_meta("is_all_book", true)
	
	# 书脊色块 - 全部用白色/浅灰色
	var spine_bar := ColorRect.new()
	spine_bar.name = "SpineBar"
	spine_bar.color = Color(1, 1, 1, 0.8)
	spine_bar.custom_minimum_size = Vector2(4, 0)
	spine_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spine_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 分类名
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = tr("category_all")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 数量标签
	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.text = str(LibraryManager.get_all_books().size())
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 横向布局
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.offset_left = 12
	hbox.offset_right = -12
	
	hbox.add_child(spine_bar)
	hbox.add_child(name_label)
	hbox.add_child(count_label)
	
	# 背景（先加，自然在底层）
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(1, 1, 1, 0.1)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchors_preset = Control.PRESET_FULL_RECT
	btn.add_child(bg)
	
	btn.add_child(hbox)
	
	# 点击事件
	btn.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_all_book_pressed()
	)
	
	# 悬停效果
	btn.mouse_entered.connect(func():
		if btn != current_selected_button:
			bg.color = Color(1, 1, 1, 0.05)
			bg.visible = true
	)
	btn.mouse_exited.connect(func():
		if btn != current_selected_button:
			bg.visible = false
	)
	
	# 替换旧按钮
	old_btn.queue_free()
	vbox.add_child(btn)
	vbox.move_child(btn, index)

# 清除所有现有的分组按钮（自定义书脊样式的，不包含 AllBook）
func clear_all_group_buttons() -> void:
	var buttons_to_remove: Array[Node] = []
	
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		# 通过是否有 group_name 元数据且不是 AllBook 来判断
		if child.has_meta("group_name") and not child.has_meta("is_all_book"):
			buttons_to_remove.append(child)
	
	for button in buttons_to_remove:
		button.queue_free()

# 创建书脊风格的分类按钮
func add_group_button(group_name_: String) -> void:
	# 外层容器（点击区域）
	var btn := Control.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.set_meta("group_name", group_name_)
	
	# 书脊色块（左侧）
	var spine_bar := ColorRect.new()
	spine_bar.name = "SpineBar"
	spine_bar.color = _get_group_color(group_name_)
	spine_bar.custom_minimum_size = Vector2(4, 0)
	spine_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spine_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 分类名标签
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = group_name_
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 数量标签
	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.text = str(_get_group_book_count(group_name_))
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 用 HBoxContainer 横向排列
	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 左右内边距用 margin 实现——直接在 btn 上用 padding style 太麻烦，用一个子容器
	hbox.position = Vector2(12, 0)
	hbox.custom_minimum_size = Vector2(0, 40)
	hbox.anchors_preset = Control.PRESET_FULL_RECT
	hbox.offset_left = 12
	hbox.offset_right = -12
	
	hbox.add_child(spine_bar)
	hbox.add_child(name_label)
	hbox.add_child(count_label)
	
	# 背景高亮（选中时显示），先加自然在底层
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(1, 1, 1, 0.1)
	bg.visible = false
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchors_preset = Control.PRESET_FULL_RECT
	btn.add_child(bg)

	btn.add_child(hbox)
	
	# 点击事件
	btn.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_get_books_by_group(group_name_)
	)
	
	# 鼠标悬停效果
	btn.mouse_entered.connect(func():
		if btn != current_selected_button:
			bg.color = Color(1, 1, 1, 0.05)
			bg.visible = true
	)
	btn.mouse_exited.connect(func():
		if btn != current_selected_button:
			bg.visible = false
	)
	
	# 找到 AllBook 并插入到它后面
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if child.has_meta("is_all_book"):
			vbox.add_child(btn)
			vbox.move_child(btn, i + 1)
			break

func _get_books_by_group(group_name_: String):
	LibraryManager.current_selected_group = group_name_
	if group_manager and is_instance_valid(group_manager):
		group_manager.queue_free()
		group_manager = null
	
	# 更新选中状态
	_refresh_selected_state()
	# 更新 AllBook 的数量
	_update_all_book_count()
	
	var search_results = LibraryManager.get_books_by_group(group_name_)
	# 1. 清空现有书架：释放所有子节点
	for child in books_container.get_children():
		child.queue_free()
	# 2. 遍历结果并重新创建场景节点
	for i in range(search_results.size()):
		var book_data_object = search_results[i] # 这是一个 Book 对象
		
		# 实例化场景
		var new_book_node = BookScene.instantiate()
		
		# 绑定数据对象到节点 (为了后续操作，如删除、编辑)
		new_book_node.data_ref = book_data_object 
		
		# 添加到容器
		books_container.add_child(new_book_node)
		LibraryManager.book_x = 500
	books_container.position.x = 0
	LibraryManager.books_container_x = 0
	print("书架过滤完成，显示书籍数量: ", search_results.size())

# 刷新所有按钮的选中状态
func _refresh_selected_state() -> void:
	current_selected_button = null
	var selected_group: String = LibraryManager.current_selected_group
	
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if not child.has_meta("group_name"):
			continue
		
		var group_name: String = child.get_meta("group_name")
		var bg: ColorRect = child.get_node("Bg")
		var spine_bar: ColorRect = child.get_node("HBox/SpineBar")
		var name_label: Label = child.get_node("HBox/NameLabel")
		
		if group_name == selected_group:
			# 选中状态
			current_selected_button = child
			bg.visible = true
			bg.color = Color(1, 1, 1, 0.18)
			spine_bar.custom_minimum_size = Vector2(8, 0)
			name_label.add_theme_font_size_override("font_size", 16)
			name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			# 整体微微右移，像书被拉出来的感觉
			var hbox: HBoxContainer = child.get_node("HBox")
			hbox.offset_left = 16
		else:
			# 未选中状态
			bg.visible = false
			spine_bar.custom_minimum_size = Vector2(4, 0)
			name_label.add_theme_font_size_override("font_size", 14)
			name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
			var hbox: HBoxContainer = child.get_node("HBox")
			hbox.offset_left = 12

# 更新 AllBook 按钮的书籍数量
func _update_all_book_count() -> void:
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if child.has_meta("is_all_book"):
			var count_label: Label = child.get_node("HBox/CountLabel")
			count_label.text = str(LibraryManager.get_all_books().size())
			return

# 根据分类名获取对应颜色
func _get_group_color(name: String) -> Color:
	var index: int = abs(name.hash()) % spine_colors.size()
	return spine_colors[index]

# 获取该分类下的书籍数量
func _get_group_book_count(group_name_: String) -> int:
	return LibraryManager.get_books_by_group(group_name_).size()


func _on_all_book_pressed() -> void:
	_get_books_by_group("")


func _on_button_pressed() -> void:
	if !get_tree().get_first_node_in_group("group_manager"):
		for child in books_container.get_children():
			child.queue_free()
		group_manager = GroupManager.instantiate()
		get_tree().root.add_child(group_manager)
