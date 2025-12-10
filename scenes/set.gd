extends Control


const CONFIG_PATH := "user://config.ini"

@onready var input: LineEdit = $BasePathInput


func _ready() -> void:
	load_config()


# 加载基础路径
func load_config() -> void:
	var cfg := ConfigFile.new()
	var err = cfg.load(CONFIG_PATH)

	if err == OK:
		var saved = cfg.get_value("settings", "base_path", "")
		input.text = saved

# 保存修改的基础路径
func save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CONFIG_PATH)

	cfg.set_value("settings", "base_path", input.text)
	cfg.save(CONFIG_PATH)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_save_button_pressed() -> void:
	save_config()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
