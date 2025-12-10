# 3DMonitor.gd 挂载在 Node3D 根节点上
extends Node3D

# 引用长方体节点
@onready var cube_node = $MeshInstance3D 

const ROTATION_SPEED = 0.005
var is_middle_mouse_down = false

func _ready():
	# 确保摄像机在固定的位置上，观察长方体（原点）
	$Camera3D.position = Vector3(0, 0, 3) 
	$Camera3D.look_at(Vector3.ZERO)

func _input(event):
	# 1. 检测鼠标中键按下的状态
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_mouse_down = event.pressed
	
	if is_middle_mouse_down and event is InputEventMouseMotion:
		# ★★★ 核心修改：旋转长方体节点，而不是整个场景或摄像机 ★★★
		
		# 水平移动 (左右拖动) -> 旋转长方体的 Y 轴
		# 使用 rotate_y 直接绕其自身的Y轴旋转
		cube_node.rotate_y(-event.relative.x * ROTATION_SPEED)
		
		# 垂直移动 (上下拖动) -> 旋转长方体的 X 轴
		# 使用 rotate_object_local 进行局部旋转，避免万向节锁死
		cube_node.rotate_object_local(Vector3.RIGHT, -event.relative.y * ROTATION_SPEED)
