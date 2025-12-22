extends Window

@onready var name_input: LineEdit = %NameInput
@onready var author_input: LineEdit = %AuthorInput
@onready var text_edit: TextEdit = $PanelContainer/MarginContainer/VBoxContainer/GridContainer/TextEdit
@onready var desc_input: LineEdit = %DescInput
@onready var book_path_input: LineEdit = %BookPathInput
@onready var cover_path_input: LineEdit = %CoverPathInput

func _ready() -> void:
	pass # Replace with function body.
