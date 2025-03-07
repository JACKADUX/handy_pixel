@tool
class_name ApplyThemeColor extends Node

@export var color_name := "color_border"

func _ready():
	apply(get_parent(), color_name)
	if not Engine.is_editor_hint():
		queue_free()
	
static func apply(node:CanvasItem, color_name:String):
	var color = ThemeDB.get_project_theme().get_color(color_name, "COLORS")
	if not color:
		color = Color.RED
	node.self_modulate = color
