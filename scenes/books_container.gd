extends Control

var is_dragging := false
var last_mouse_x := 0.0
var velocity_x := 0.0

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
	self.position.x = clamp(self.position.x, -100*LibraryManager._books.size()+1000, 200)
