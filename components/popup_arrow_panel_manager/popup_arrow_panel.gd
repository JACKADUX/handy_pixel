extends Control

@onready var margin_container: MarginContainer = %MarginContainer
@onready var triangle: TextureRect = %Triangle
@onready var triangle_2: TextureRect = %Triangle2

@onready var main_panel: PanelContainer = %MainPanel

var free_panel_on_hide := false
var _tri_start_pos : Vector2
var _tri_2_start_pos : Vector2

func _ready() -> void:
	visibility_changed.connect(func():
		if not visible and free_panel_on_hide:
			queue_free()
	)
	_tri_start_pos = triangle.position
	_tri_2_start_pos = triangle_2.position

func add_panel(control:Control):
	margin_container.add_child(control)

func get_panel() -> Control:
	return margin_container.get_child(0)

func set_popup_side(side:Side, panel_offset):
	triangle.rotation_degrees = 90 *(1 + int(side))
	triangle_2.rotation_degrees = triangle.rotation_degrees
	#var ofs = Vector2.from_angle(PI*0.5*int(side))*24
	triangle.position = _tri_start_pos + panel_offset
	triangle_2.position = _tri_2_start_pos + panel_offset
	
	match side:
		SIDE_LEFT:
			main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE)
			main_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			main_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		SIDE_TOP:
			main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
			main_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			main_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		SIDE_RIGHT:
			main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE)
			main_panel.grow_horizontal = Control.GROW_DIRECTION_END
			main_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		SIDE_BOTTOM:
			main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
			main_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
			main_panel.grow_vertical = Control.GROW_DIRECTION_END
