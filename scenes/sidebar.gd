extends PanelContainer

@onready var label: Label = $VBoxContainer/Label
@onready var group_name: LineEdit = $VBoxContainer/GroupName
@onready var add_group: Button = $VBoxContainer/AddGroup
@onready var vbox: VBoxContainer = $VBoxContainer

@onready var books_container: Control = $"../VBoxContainer/BooksContainer"
@onready var BookScene := preload("res://scenes/book.tscn")


func _ready() -> void:
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

# 清除所有现有的分组按钮
func clear_all_group_buttons() -> void:
	# 找出并删除所有分组按钮
	var buttons_to_remove: Array[Node] = []
	
	for i in range(vbox.get_child_count()):
		var child = vbox.get_child(i)
		if child is Button and child.flat and child.name != "AllBook":  # 通过 flat 属性判断是分组按钮
			buttons_to_remove.append(child)
	
	# 删除这些按钮
	for button in buttons_to_remove:
		button.queue_free()

func add_group_button(group_name_: String) -> void:
	var button = Button.new()
	button.text = group_name_
	button.flat = true
	button.pressed.connect(func(): _get_books_by_group(group_name_))
	
	# 找到 AllBook 并插入到它后面
	for i in range(vbox.get_child_count()):
		if vbox.get_child(i) is Button and vbox.get_child(i).name == "AllBook":
			vbox.add_child(button)
			vbox.move_child(button, i + 1)
			break

func _on_add_group_pressed() -> void:
	var group = group_name.text.strip_edges()
	if group != "":
		# 检查分组是否已存在
		if is_group_exists_in_config(group):
			print("分组已存在: ", group)
			return
		
		save_group_to_config(group)
		group_name.text = ""  # 清空输入框
		print("分组添加成功: ", group)
		load_groups()
		

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
	
func _get_books_by_group(group_name_: String):
	var search_results = LibraryManager.get_books_by_group(group_name_)
	# 1. 清空现有书架：释放所有子节点
	for child in books_container.get_children():
		child.queue_free()
	# 2. 遍历结果并重新创建场景节点
	for i in range(search_results.size()):
		var book_data_object = search_results[i] # 这是一个 BookData 对象
		
		# 实例化场景
		var new_book_node = BookScene.instantiate()
		
		# 绑定数据对象到节点 (为了后续操作，如删除、编辑)
		new_book_node.data_ref = book_data_object 
		
		# 添加到容器
		books_container.add_child(new_book_node)
		LibraryManager.book_x = 500
	books_container.position.x = 0
	print("书架过滤完成，显示书籍数量: ", search_results.size())


func _on_all_book_pressed() -> void:
	_get_books_by_group("")
