extends Window

@onready var name_input: LineEdit = %NameInput
@onready var author_input: LineEdit = %AuthorInput
@onready var introduction_input: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/Introduction
@onready var book_path_input: LineEdit = %BookPathInput
@onready var spine_path_input: LineEdit = %SpinePathInput
@onready var cover_path_input: LineEdit = %CoverPathInput
@onready var group_option: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/GroupOption


@onready var btn_select_book: Button = %BtnSelectBook
@onready var btn_select_spine: Button = %BtnSelectSpine
@onready var btn_select_cover: Button = %BtnSelectCover
@onready var btn_confirm: Button = %BtnConfirm
@onready var books_container = $"../Main/BooksContainer"
@onready var change_books_container = $"../../.."
@onready var sidebar = $"../../../../Sidebar"

var current_file_dialog: FileDialog = null
var target_input: LineEdit = null
var target_id: String

func _ready() -> void:
	# 连接关闭请求信号
	close_requested.connect(_on_close_requested)
	# 连接按钮信号
	btn_select_book.pressed.connect(_on_select_book_pressed)
	btn_select_spine.pressed.connect(_on_select_spine_pressed)
	btn_select_cover.pressed.connect(_on_select_cover_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	var groups = load_groups_from_config("user://config.ini")
	setup_group_options(groups)
	group_option.select(-1)

func _on_close_requested() -> void:
	# 当点击关闭按钮时隐藏窗口
	hide()
	if get_parent() == get_tree().root:
		books_container.is_dragging = false

func _on_select_book_pressed() -> void:
	target_input = book_path_input
	show_file_dialog("选择书籍文件")


func _on_select_spine_pressed() -> void:
	target_input = spine_path_input
	show_file_dialog("选择书脊文件")


func _on_select_cover_pressed() -> void:
	target_input = cover_path_input
	show_file_dialog("选择封面文件")

	
func show_file_dialog(_title: String, filters: PackedStringArray = []) -> void:
	# 如果已经有文件对话框存在，先清理
	if current_file_dialog:
		current_file_dialog.queue_free()
	
	# 创建新的文件对话框
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = BookData.base_path  # ← 指定打开的文件夹
	dialog.title = _title
	
	# 可选：添加文件过滤器
	if filters.size() > 0:
		dialog.filters = filters
	
	# 连接信号
	dialog.file_selected.connect(_on_file_selected)
	dialog.canceled.connect(_on_file_dialog_canceled)
	
	add_child(dialog)
	current_file_dialog = dialog
	
	# 显示对话框
	dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	var target_dir: String
	var file_name = path.get_file()
	if target_input != book_path_input:
		# 根据当前要设置的输入框类型，选择不同的目标目录
		if target_input == spine_path_input:
			target_dir = "user://book_textures/"
		elif target_input == cover_path_input:
			target_dir = "user://book_cover_textures/"

		DirAccess.make_dir_recursive_absolute(target_dir)
		var target = target_dir + file_name
		copy_file(path, target)
		
		target_input.text = target
		print("已选择文件: ", path)
	else:
		target_input.text = get_relative_path(path)
	
	# 清理文件对话框
	if current_file_dialog:
		current_file_dialog.queue_free()
		current_file_dialog = null
		
	# 判断两个路径输入框是否都不为空
	var book_path_valid = not book_path_input.text.strip_edges().is_empty()
	var spine_path_valid = not spine_path_input.text.strip_edges().is_empty()
	# 设置按钮的禁用状态
	btn_confirm.disabled = not (book_path_valid and spine_path_valid)


func _on_file_dialog_canceled() -> void:
	print("文件选择已取消")
	if current_file_dialog:
		current_file_dialog.queue_free()
		current_file_dialog = null

func _on_confirm_pressed() -> void:
	# 获取所有输入
	var path = book_path_input.text.strip_edges()
	var texture = spine_path_input.text.strip_edges()
	var book_cover_texture = cover_path_input.text.strip_edges()
	var book_name = name_input.text.strip_edges()
	var author = author_input.text.strip_edges()
	var introduction = introduction_input.text.strip_edges()  # 根据你的变量名
	var group_name = group_option.text
	
	# 如果没输入书名，用文件名
	if book_name.is_empty() and not path.is_empty():
		book_name = path.get_file().get_basename()
	if self.title == "添加书籍":
		# 调用方法
		LibraryManager.add_new_book(path,texture,book_name,book_cover_texture,author,introduction,group_name)
	else:
		LibraryManager.update_book_info(target_id,book_name,path,texture,book_cover_texture,author,introduction,group_name)
		sidebar._get_books_by_group(LibraryManager.current_selected_group)
		change_books_container.position.x = LibraryManager.books_container_x
	hide()


# 复制书籍文件方法
func copy_file(src_path: String, dst_path: String) -> int:
	var src = FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		push_error("无法打开源文件: " + src_path)
		return ERR_CANT_OPEN

	var dst = FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		push_error("无法打开目标文件: " + dst_path)
		return ERR_CANT_OPEN

	dst.store_buffer(src.get_buffer(src.get_length()))
	return OK

# 把绝对路径改成相对路径的方法
func get_relative_path(abs_path: String) -> String:
	if not BookData.base_path.ends_with("/"):
		BookData.base_path += "/"

	# Godot 字符串处理
	if abs_path.begins_with(BookData.base_path):
		return abs_path.replace(BookData.base_path, "")
	return abs_path  # 不在 base_path 下就直接返回原路径

# 在窗口脚本中添加这个方法
func load_book_data(book_data: Dictionary) -> void:
	"""加载书籍数据到表单"""
	target_id = book_data.get("book_id","")
	name_input.text = book_data.get("name", "")
	author_input.text = book_data.get("author", "")
	book_path_input.text = book_data.get("rel_path", "")
	spine_path_input.text = book_data.get("book_texture", "")
	cover_path_input.text = book_data.get("book_cover_texture", "")
	introduction_input.text = book_data.get("introduction", "")
	group_option.text = book_data.get("group_name", "")
	
	self.title = "编辑书籍"
	btn_confirm.disabled = false
	btn_confirm.text = "确定更改"
	# 显示窗口
	popup_centered()

func load_groups_from_config(config_path: String) -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(config_path)
	if err != OK:
		print("无法加载配置文件: ", config_path)
		return {}
	
	var groups = {}
	if config.has_section("group"):
		var keys = config.get_section_keys("group")
		for key in keys:
			var value = config.get_value("group", key)
			groups[int(key)] = value  # key转为整数，value是字符串
	
	return groups
	
func setup_group_options(groups: Dictionary):
	group_option.clear()
	
	# 按key排序，确保顺序
	var sorted_keys = groups.keys()
	sorted_keys.sort()
	
	for key in sorted_keys:
		var text = groups[key]
		group_option.add_item(text, key)
