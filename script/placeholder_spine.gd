extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var label: Label = $Label

# 预设的书脊颜色（从现有书脊颜色里挑了几个常见的）
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

func _ready() -> void:
	pass

# 根据书名（或ID）选择一个固定颜色，保证同一本书每次颜色一样
func set_book_name(name: String) -> void:
	if name == "":
		name = "未命名"
	label.text = _to_vertical_text(name)
	# 用书名的 hash 选颜色，保证同一本书颜色一致
	var color_index: int = abs(name.hash()) % spine_colors.size()
	color_rect.color = spine_colors[color_index]

# 设置占位书脊的高度（宽度按比例自适应）
func set_height(height: float) -> void:
	# 宽度为高度的 8%，类似真实书脊厚度
	var width: float = max(24.0, height * 0.08)
	color_rect.size = Vector2(width, height)
	label.size = Vector2(width, height * 0.8)
	label.position = Vector2(0, height * 0.1)
	size = Vector2(width, height)

# 将文字转为竖排（每个字一行）
func _to_vertical_text(text: String) -> String:
	var result: String = ""
	for i in range(text.length()):
		result += text[i] + "\n"
	# 去掉最后一个换行
	if result.ends_with("\n"):
		result = result.left(result.length() - 1)
	return result
