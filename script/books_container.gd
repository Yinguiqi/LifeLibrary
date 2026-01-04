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
func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event):
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

		var target_x: float = child.get_meta("target_x")

		# 这里你可以换成自己项目里用的 Tween 管理方式
		var tween := create_tween()
		tween.tween_property(
			child,
			"position:x",
			target_x,
			0.25
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
