# res://BookData.gd
extends RefCounted

# 定义你的书籍属性
var id: String = ""           # 例如 "Book4"
var name: String = ""         # 例如 "第01卷"
var rel_path: String = ""     # 例如 "漫画/..."
var book_texture: String = "" # 例如 "res://..."

# 初始化函数 (手动调用)
func initialize(_id: String, _name: String, _path: String, _texture: String):
	id = _id
	name = _name
	rel_path = _path
	book_texture = _texture
