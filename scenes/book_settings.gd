extends Control

const CONFIG_PATH := "user://config.ini"

@onready var input: LineEdit = $BookIDInput
@onready var input2: LineEdit = $BookIDInput2


func _ready() -> void:
	# 载入当前要编辑的ID（从 Book 传过来的）
	input.text = BookData.book_rel_path
	input2.text = BookData.book_texture_path


func save_book_id():
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)

	# 将当前 book_id 保存到 ini
	cfg.set_value(BookData.book_id, "rel_path", input.text)
	cfg.set_value(BookData.book_id, "book_texture", input2.text)
	cfg.save(CONFIG_PATH)

	# 更新全局变量（以便书本场景回来后能更新显示）
	BookData.book_rel_path = input.text


func _on_save_button_pressed() -> void:
	save_book_id()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
