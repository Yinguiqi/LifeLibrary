extends Control

var is_dragging := false
var last_mouse_x := 0.0
var velocity_x := 0.0

# 当前展开的书
var expanded_book: Control = null
# 当前展开封面的宽度
var expanded_cover_width: float = 0.0
# 存储所有展开的书籍（而不仅仅是一本）
var expanded_books := {}  # Dictionary: Book -> cover_width

# 书籍拖拽相关
var dragging_book: Control = null  # 当前正在拖拽的书籍
var book_original_index := -1  # 拖拽开始时书籍的原始索引
var last_swap_index := -1  # 上次交换的索引，避免频繁交换

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event):
	# 如果正在拖拽书籍，禁用容器本身的拖拽
	if dragging_book != null:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			last_mouse_x = get_global_mouse_position().x
			velocity_x = 0.0
		else:
			is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var current_x = get_global_mouse_position().x
		var dx = current_x - last_mouse_x
		position.x += dx
		velocity_x = dx
		last_mouse_x = current_x

func _process(delta):
	if not is_dragging:
		self.position.x += velocity_x
		velocity_x *= 0.9  # 惯性阻尼（越小停得越快）
		
		# 惯性停止时更新
		if abs(velocity_x) < 0.1 and abs(velocity_x) > 0:  # 速度接近0但还不是0
			LibraryManager.books_container_x = self.position.x
	self.position.x = clamp(self.position.x, -LibraryManager.book_x+1000, 0)
	
# 对外暴露的方法：由 Book 调用
func on_book_expand(book: Control, cover_width: float) -> void:
	# 添加或更新展开状态
	expanded_books[book] = cover_width
	_relayout_books()
	

# 对外暴露的方法：收起
func on_book_collapse(book: Control) -> void:
	# 移除展开状态
	if expanded_books.has(book):
		expanded_books.erase(book)
		_relayout_books()


func _relayout_books() -> void:
	var x_cursor := 500.0
	var children := get_children()

	for child in children:
		if not child is Control:
			continue
		# 如果封面在左边
		if  expanded_books.has(child) and child.book_cover.position.x < 0:
			x_cursor += child.book_cover.size.x * child.scale.x
		# 1️⃣ 设置目标位置
		child.set_meta("target_x", x_cursor)

		# 2️⃣ 累加基础宽度（书脊宽）
		x_cursor += child.book_scale_width
		x_cursor += LibraryManager.book_spacing

		# 3️⃣ 如果这本书是展开的，额外占用封面宽度
		if expanded_books.has(child) and child.book_cover.position.x > 0:
			x_cursor += expanded_books[child]

	# 4️⃣ 触发动画
	_animate_books()
	
func _animate_books() -> void:
	for child in get_children():
		if not child is Control:
			continue

		if not child.has_meta("target_x"):
			continue

		# 跳过正在拖拽的书籍，让它继续跟随鼠标
		if child == dragging_book:
			continue

		var target_x: float = child.get_meta("target_x")

		# 这里你可以换成自己项目里用的 Tween 管理方式
		var tween := create_tween()
		tween.tween_property(
			child,
			"position:x",
			target_x,
			0.25
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# 书籍拖拽相关方法
func set_book_dragging(book: Control, dragging: bool) -> void:
	if dragging:
		dragging_book = book
		book_original_index = _get_book_index(book)
		last_swap_index = book_original_index
		# 禁用容器拖拽，防止冲突
		is_dragging = false
		velocity_x = 0.0
	else:
		# 拖拽结束时，确保容器不会继续惯性运动
		is_dragging = false
		velocity_x = 0.0
		dragging_book = null
		book_original_index = -1
		last_swap_index = -1

func on_book_drag_start(book: Control) -> void:
	# 拖拽开始时，可以添加视觉反馈
	pass

func on_book_drag_end(book: Control) -> void:
	# 拖拽结束时，重新排列所有书籍并交换数据
	_reorder_books_after_drag()

func check_swap_position(dragging_book_node: Control) -> void:
	if dragging_book_node == null:
		return
	
	var children = get_children()
	# 过滤出书籍节点
	var books = []
	for child in children:
		if child is Control and child.has_method("apply_texture"):
			books.append(child)
	
	if books.size() <= 1:
		return
	
	var drag_book_index = books.find(dragging_book_node)
	if drag_book_index == -1:
		return
	
	var drag_book_x = dragging_book_node.position.x
	
	# 检查左侧书籍
	if drag_book_index > 0:
		var left_book = books[drag_book_index - 1]
		var left_book_half_x = left_book.position.x + left_book.book_scale_width * 0.5
		
		# 如果拖拽的书籍的 position.x 到达了上一本书 book_scale_width 的一半位置
		# 即：拖拽书的 x < 上一本书的 x + 上一本书宽度的一半
		if drag_book_x < left_book_half_x:
			if last_swap_index != drag_book_index - 1:
				_swap_books_immediate(dragging_book_node, left_book)
				# 更新 last_swap_index 为交换后的新索引
				last_swap_index = drag_book_index - 1
				return
	
	# 检查右侧书籍
	if drag_book_index < books.size() - 1:
		var right_book = books[drag_book_index + 1]
		var right_book_half_x = right_book.position.x + right_book.book_scale_width * 0.5
		
		# 如果拖拽的书籍的 position.x 到达了下一本书 book_scale_width 的一半位置
		# 即：拖拽书的右边缘 > 下一本书的中心点
		var drag_book_right_x = drag_book_x + dragging_book_node.book_scale_width
		if drag_book_right_x > right_book_half_x:
			if last_swap_index != drag_book_index + 1:
				_swap_books_immediate(dragging_book_node, right_book)
				# 更新 last_swap_index 为交换后的新索引
				last_swap_index = drag_book_index + 1
				return

func _swap_books_immediate(book1: Control, book2: Control) -> void:
	# 交换两个书籍在容器中的顺序
	var index1 = _get_book_index(book1)
	var index2 = _get_book_index(book2)
	
	if index1 == -1 or index2 == -1:
		return
	
	# 确保 index1 < index2，方便处理
	if index1 > index2:
		var temp = index1
		index1 = index2
		index2 = temp
		var temp_book = book1
		book1 = book2
		book2 = temp_book
	
	# 交换节点顺序（先移动后面的，再移动前面的）
	move_child(book2, index1)
	move_child(book1, index2)
	
	# 交换数据 id
	if book1.data_ref and book2.data_ref:
		var temp_id = book1.data_ref.id
		book1.data_ref.id = book2.data_ref.id
		book2.data_ref.id = temp_id
		
		# 保存到 JSON
		LibraryManager.save_data_to_json()
	
	# 重新计算所有非拖拽书籍的位置（包括 book_spacing），让它们移动到正确位置
	_reposition_books_during_drag()

func _reposition_books_during_drag() -> void:
	# 在拖拽过程中重新计算所有非拖拽书籍的位置
	var x_cursor := 500.0
	var children = get_children()
	
	for child in children:
		if not child is Control:
			continue
		if not child.has_method("apply_texture"):  # 只处理书籍节点
			continue
		
		# 跳过正在拖拽的书籍
		if child == dragging_book:
			# 跳过拖拽书籍，但继续累加位置，为下一个书籍计算正确位置
			# 如果封面在左边
			if expanded_books.has(child) and child.book_cover.position.x < 0:
				x_cursor += child.book_cover.size.x * child.scale.x
			x_cursor += child.book_scale_width
			x_cursor += LibraryManager.book_spacing
			# 如果这本书是展开的，额外占用封面宽度
			if expanded_books.has(child) and child.book_cover.position.x > 0:
				x_cursor += expanded_books[child]
			continue
		
		# 如果封面在左边
		if expanded_books.has(child) and child.book_cover.position.x < 0:
			x_cursor += child.book_cover.size.x * child.scale.x
		
		# 设置目标位置
		var target_x = x_cursor
		
		# 累加基础宽度（书脊宽）
		x_cursor += child.book_scale_width
		x_cursor += LibraryManager.book_spacing
		
		# 如果这本书是展开的，额外占用封面宽度
		if expanded_books.has(child) and child.book_cover.position.x > 0:
			x_cursor += expanded_books[child]
		
		# 如果当前位置与目标位置不同，移动到目标位置
		if abs(child.position.x - target_x) > 1.0:  # 允许1像素的误差
			var tween = create_tween()
			tween.tween_property(child, "position:x", target_x, 0.2)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.set_ease(Tween.EASE_OUT)

func _reorder_books_after_drag() -> void:
	# 重新计算所有书籍的位置
	var x_cursor := 500.0
	var children = get_children()
	
	for child in children:
		if not child is Control:
			continue
		if not child.has_method("apply_texture"):  # 只处理书籍节点
			continue
		
		# 如果封面在左边
		if expanded_books.has(child) and child.book_cover.position.x < 0:
			x_cursor += child.book_cover.size.x * child.scale.x
		
		# 设置目标位置（包括拖拽的书籍）
		child.set_meta("target_x", x_cursor)
		
		# 累加基础宽度（书脊宽）
		x_cursor += child.book_scale_width
		x_cursor += LibraryManager.book_spacing
		
		# 如果这本书是展开的，额外占用封面宽度
		if expanded_books.has(child) and child.book_cover.position.x > 0:
			x_cursor += expanded_books[child]
	
	# 触发动画，现在可以包括所有书籍（因为拖拽已结束）
	_animate_books()

func _get_book_index(book: Control) -> int:
	# 获取书籍在容器中的索引
	var children = get_children()
	for i in range(children.size()):
		if children[i] == book:
			return i
	return -1
