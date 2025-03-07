class_name Canvas extends Node2D

@onready var canvas_data :CanvasData = SystemManager.canvas_system.canvas_data

@export var cell_size :int= 10

func _ready() -> void:
	canvas_data.data_changed.connect(queue_redraw)

func _draw():
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE*cell_size)
	var texture = canvas_data.get_texture()
	if texture:
		draw_texture(texture, Vector2.ZERO)
