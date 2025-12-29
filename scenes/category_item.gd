extends HBoxContainer


@onready var name_label: Label = $NameLabel
@onready var rename_button: Button = $RenameButton
@onready var delete_button: Button = $DeleteButton

func set_name_text(text: String) -> void:
	name_label.text = text



func _on_rename_button_pressed() -> void:
	var window = Window.new()
	window.title = "更改分类名称"
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
	search_btn.text = "更改"
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
			update_group_to_config(group,name_label.text)
			print("分组更改成功: ", group)
		window.hide()
		set_name_text(group)
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

# 更改分组名称到配置文件
func update_group_to_config(new_name: String,old_name: String) -> void:
	var cfg_save = ConfigFile.new()
	cfg_save.load("user://config.ini")
		# 获取 [group] 部分的所有键
	var group_keys = cfg_save.get_section_keys("group")
	
	# 遍历所有键，查找值为 old_name 的键
	var key_to_update = ""
	for key in group_keys:
		var value = cfg_save.get_value("group", key, "")
		if value == old_name:
			key_to_update = key
			break
	
	cfg_save.set_value("group", key_to_update, new_name)
	print("已将键 '", key_to_update, "' 的值从 '", old_name, "' 更新为 '", new_name, "'")
	
	cfg_save.save("user://config.ini")

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

func _on_delete_button_pressed() -> void:
	var cfg = ConfigFile.new()
	cfg.load("user://config.ini")
		# 获取 [group] 部分的所有键
	var group_keys = cfg.get_section_keys("group")
	for key in group_keys:
		if cfg.get_value("group", key) == name_label.text:
						# 删除找到的键值对
			cfg.erase_section_key("group", key)
			cfg.save("user://config.ini")
			
			# 删除当前节点
	queue_free()
	var manager = get_tree().get_first_node_in_group("category_manager")
	manager.load_groups()
	return  # 找到并删除后直接退出
