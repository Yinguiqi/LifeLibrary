# res://LibraryManager.gd
extends Node

# --- 配置 ---
const JSON_PATH = "user://books_data.json"
# 引用 BookData 脚本，避开 class_name 冲突
const BookDataScript = preload("res://books_data.gd")
var current_book_data: RefCounted = null
var base_path: String = ""
# --- 内存数据 ---
# 这个数组里装的全是 BookDataScript 的实例对象
var _books: Array = [] 

func _ready():
	print("LibraryManager 启动，正在加载数据...")
	load_data_from_json()

# --- 1. 读取 (R) ---

# 从 JSON 加载到内存数组
func load_data_from_json():
	_books.clear()
	
	if not FileAccess.file_exists(JSON_PATH):
		print("未找到 JSON 文件，初始化为空库。")
		return

	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		var data_array = json.data as Array
		
		# 将字典转换回对象
		for dict in data_array:
			var new_book = BookDataScript.new()
			# 从字典取值，如果没找到则给个默认值
			new_book.id = dict.get("id", "")
			new_book.name = dict.get("name", "未命名")
			new_book.rel_path = dict.get("rel_path", "")
			new_book.book_texture = dict.get("book_texture", "")
			new_book.book_cover_texture = dict.get("book_cover_texture", "")
			new_book.scale_factor = dict.get("scale_factor", "")
			
			_books.append(new_book)
			
		# 排序：让 Book4 排在 Book10 前面
		_sort_books()
		print("成功加载 %d 本书" % _books.size())
	else:
		print("JSON 解析失败: ", json.get_error_message())

# 获取所有书（给 UI 用）
func get_all_books() -> Array:
	return _books

# 根据 ID 获取单本书对象
func get_book_by_id(target_id: String):
	for book in _books:
		if book.id == target_id:
			return book
	return null

# --- 2. 保存 (W) ---

# 将内存数组保存回 JSON
func save_data_to_json():
	var data_to_save = []
	
	# 将对象转换回字典
	for book in _books:
		data_to_save.append({
			"id": book.id,
			"name": book.name,
			"rel_path": book.rel_path,
			"book_texture": book.book_texture,
			"book_cover_texture": book.book_cover_texture,
			"scale_factor": book.scale_factor
		})
	
	var json_string = JSON.stringify(data_to_save, "\t")
	var file = FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("数据已保存。")
	else:
		print("保存文件失败！")

# --- 3. 更新 (U) ---

# 你的 UI 应该调用这个函数来修改数据
func update_book_info(target_id: String, new_name:String, new_path: String, new_texture: String,new_cover_texture: String,new_scale_factor: String):
	var book = get_book_by_id(target_id)
	if book:
		book.rel_path = new_path
		if new_texture.begins_with("user://book_textures/"):
			book.book_texture = new_texture
		elif new_cover_texture.begins_with("user://book_cover_textures/"):
			book.book_cover_texture = new_cover_texture
		book.name = new_name
		book.scale_factor = new_scale_factor
		# 改完内存立刻存盘
		save_data_to_json()
		print("书籍 %s 更新成功" % target_id)
	else:
		print("错误：找不到 ID 为 %s 的书" % target_id)

# --- 4. 新增 (C) ---

func add_new_book(path: String, texture: String = "",book_cover_texture: String = ""):
	# 自动生成 ID: Book + (当前数量+1)
	# 为了防止 ID 重复，也可以用时间戳，但这里沿用你的逻辑
	var new_index = _books.size() + 1
	var new_id = "Book%d" % new_index
	
	# 防止删除了中间的书导致 ID 重复 (简单的防重逻辑)
	while get_book_by_id(new_id) != null:
		new_index += 1
		new_id = "Book%d" % new_index
	
	var new_book = BookDataScript.new()
	new_book.initialize(new_id, "新书", path, texture,book_cover_texture)
	new_book.scale_factor = 1
	_books.append(new_book)
	save_data_to_json()
	return new_book

# --- 辅助：排序 ---
func _sort_books():
	_books.sort_custom(func(a, b):
		# 提取 ID 里的数字进行排序
		var id_a = int(a.id.trim_prefix("Book"))
		var id_b = int(b.id.trim_prefix("Book"))
		return id_a < id_b
	)

# 辅助函数：将一个字典转换为一个 BookData 对象
func create_book_object_from_dict(dict: Dictionary) -> RefCounted:
	var book_object = BookDataScript.new()
	
	# 使用 initialize 或直接赋值，确保所有属性都被设置
	book_object.initialize(
		dict.get("id", ""),
		dict.get("name", ""),
		dict.get("rel_path", ""),
		dict.get("book_texture", ""),
		dict.get("book_cover_texture", ""),
		dict.get("scale_factor", "")
	)
	
	# 别忘了同步旧变量，以防万一（根据你的过渡方案）
	#book_object.book_id = book_object.id
	# ... 其他旧变量的同步 ...
	
	return book_object

## 根据 ID 删除一本书
## 返回 true 如果成功删除，返回 false 如果未找到
func delete_book_by_id(target_id: String) -> bool:
	var index_to_remove = -1
	
	# 1. 遍历数组，找到目标 ID 的索引
	for i in range(_books.size()):
		var book = _books[i]
		if book.id == target_id:
			index_to_remove = i
			break
			
	if index_to_remove != -1:
		# 2. 从内存数组中移除该对象
		var removed_book = _books[index_to_remove]
		_books.remove_at(index_to_remove)
		
		# (可选) 确保被移除的对象没有残留引用
		# 如果你不需要对被删除的对象做额外操作，这一步是安全的
		if removed_book is RefCounted:
			removed_book.unreference() 
		
		# 3. 立即保存整个数组到 JSON 文件
		save_data_to_json()
		
		print("成功删除书籍 ID: ", target_id)
		
		# 4. 如果当前被选中的是这本书，清除选中状态
		if current_book_data != null and current_book_data.id == target_id:
			current_book_data = null
			
		return true
	else:
		print("错误：未找到 ID 为 %s 的书籍，无法删除。" % target_id)
		return false

## 根据书名查询所有匹配的书籍
## 可以选择是否进行模糊匹配 (contains) 或精确匹配
func get_books_by_name(target_name: String, fuzzy_match: bool = false) -> Array:
	var results: Array = []
	var search_term = target_name.to_lower() # 转换为小写，便于不区分大小写地查询

	# 遍历内存中的所有书籍对象
	for book in _books:
		var book_name_lower = book.name.to_lower()
		
		var is_match = false
		
		if fuzzy_match:
			# 模糊匹配：只要书名包含目标词汇即可
			if book_name_lower.contains(search_term):
				is_match = true
		else:
			# 精确匹配：书名必须完全相同
			if book_name_lower == search_term:
				is_match = true
		
		if is_match:
			results.append(book)
	if target_name == "":
		results = _books	.duplicate()
	return results
