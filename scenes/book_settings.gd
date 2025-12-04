extends Control

const CONFIG_PATH := "user://config.ini"

@onready var input: LineEdit = $BookIDInput
@onready var input2: LineEdit = $BookIDInput2
@onready var input3: LineEdit = $BookIDInput3
@onready var input4: LineEdit = $BookIDInput4
var current_book = LibraryManager.current_book_data

func _ready() -> void:
	# 载入当前要编辑的ID（从 Book 传过来的）
	input.text = current_book.rel_path
	input2.text = current_book.book_texture
	input3.text = current_book.name
	input4.text = str(current_book.scale_factor)
	

func save_book_id():
	# 更新全局变量（以便书本场景回来后能更新显示）
	LibraryManager.update_book_info(current_book.id,input3.text, input.text, input2.text ,input4.text)

func _on_save_button_pressed() -> void:
	save_book_id()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
