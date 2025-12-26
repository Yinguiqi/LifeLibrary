# res://BookData.gd
extends RefCounted

# 定义你的书籍属性
var id: String = ""           # 例如 "Book4"
var author: String = ""       # 作者
var introduction: String = ""       # 简介
var group_name: String = ""       # 简介
var name: String = ""         # 例如 "第01卷"
var rel_path: String = ""     # 例如 "漫画/..."
var book_texture: String = "" # 例如 "res://..."
var book_cover_texture: String = "" # 例如 "res://..."


# 初始化函数 (手动调用)
func initialize(_id: String, _name: String, _path: String, _texture: String, _book_cover_texture: String, _author: String, _introduction: String, _group_name: String):
	id = _id
	author = _author
	introduction = _introduction
	name = _name
	rel_path = _path
	book_texture = _texture
	book_cover_texture = _book_cover_texture
	group_name = _group_name
