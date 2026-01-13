extends Control

@export var CATEGORY_ITEM_SCENE: PackedScene

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var category_item: HBoxContainer = $VBoxContainer/CategoryItem

func _ready() -> void:
	group_list()

# 添加分组按钮
func _on_add_category_button_pressed() -> void:
	var window = Window.new()
	window.title = "增加分类"
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
	line_edit.placeholder_text = "请输入分类名称"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.custom_minimum_size = Vector2(0, 36)
	hbox.add_child(line_edit)

	# ===== 搜索按钮 =====
	var search_btn = Button.new()
	search_btn.text = "添加"
	search_btn.custom_minimum_size = Vector2(80, 36)
	hbox.add_child(search_btn)

	# ===== 信号 =====
	search_btn.pressed.connect(func():
		var group = line_edit.text.strip_edges()
		if group != "":
			# 检查分组是否已存在
			if is_group_exists_in_config(group):
				print("分组已存在: ", group)
				return
			save_group_to_config(group)
			print("分组添加成功: ", group)
		window.hide()
		group_list()
		var manager = get_tree().get_first_node_in_group("category_manager")
		manager.load_groups()
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

# 检查分组是否存在于配置文件中
func is_group_exists_in_config(_group_name: String) -> bool:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.ini") == OK:
		if cfg.has_section("group"):
			var keys = cfg.get_section_keys("group")
			for key in keys:
				var existing_group = cfg.get_value("group", key)
				if existing_group == _group_name:
					return true
	return false
	
# 保存分组到配置文件
func save_group_to_config(group: String) -> void:
	var cfg_save = ConfigFile.new()
	cfg_save.load("user://config.ini")
	
	# 查找下一个可用的键名
	var index = 1
	while cfg_save.has_section_key("group", str(index)):
		index += 1
	
	# 保存分组
	cfg_save.set_value("group", str(index), group)
	cfg_save.save("user://config.ini")

func group_list():
	# 删除所有 CATEGORY_ITEM_SCENE 实例节点
	for child in v_box_container.get_children():
		# 通过场景文件路径判断
		if child.scene_file_path == CATEGORY_ITEM_SCENE.resource_path:
			child.queue_free()
	var cfg = ConfigFile.new()
	if cfg.load("user://config.ini") == OK and cfg.has_section("group"):
		var keys = cfg.get_section_keys("group")
		for key in keys:
			var group = cfg.get_value("group", key)
			var item := CATEGORY_ITEM_SCENE.instantiate()
			v_box_container.add_child(item)
			item.set_name_text(group)
