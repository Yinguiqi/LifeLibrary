extends HBoxContainer


@onready var name_label: Label = $NameLabel

func set_name_text(text: String) -> void:
	name_label.text = text
