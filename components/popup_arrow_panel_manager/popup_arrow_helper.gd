extends Node

@export var popup_panel : PackedScene
@export var popup_side :Side
@export var offset :int = 96
@export var panel_offset := Vector2(0,0)

func _ready() -> void:
	var parent = get_parent()
	if parent is Button:
		parent.pressed.connect(func():
			var arrow_panel = SystemManager.ui_system.popup_arrow_panel_manager.new_popup_panel(popup_panel.instantiate())
			arrow_panel.set_popup_side(popup_side, -panel_offset)
			var offset = Vector2.from_angle(PI*0.5*int(popup_side)) * offset
			arrow_panel.global_position = parent.get_global_rect().get_center() - offset + panel_offset
		)
	
