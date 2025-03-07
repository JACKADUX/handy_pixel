extends Control

@onready var margin_container: MarginContainer = %MarginContainer
@onready var triangle: TextureRect = %Triangle
@onready var triangle_2: TextureRect = %Triangle2

@onready var main_panel: PanelContainer = %MainPanel

func add_panel(control:Control):
	margin_container.add_child(control)

func set_popup_side(side:Side, panel_offset):
	triangle.rotation_degrees = 90 *(1 + int(side))
	triangle_2.rotation_degrees = triangle.rotation_degrees
	#var ofs = Vector2.from_angle(PI*0.5*int(side))*24
	triangle.position += panel_offset
	triangle_2.position += panel_offset
	
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
