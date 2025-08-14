extends PanelContainer

@onready var main_button: Button = %Button
@onready var texture_rect: TextureRect = %TextureRect

@onready var margin_container: MarginContainer = %MarginContainer

@onready var delete_button: Button = %DeleteButton
@onready var export_button: Button = %ExportButton
@onready var buttons_container: HBoxContainer = %ButtonsContainer

@onready var size_label: Label = %SizeLabel

func set_margin(value:int):
	margin_container.add_theme_constant_override("margin_left", value)
	margin_container.add_theme_constant_override("margin_right", value)
	margin_container.add_theme_constant_override("margin_top", value)
	margin_container.add_theme_constant_override("margin_bottom", value)

var _press_position : Vector2

func _gui_input(event: InputEvent) -> void:
	if InputEventUtils.is_pressed(event):
		_press_position = Vector2.ZERO
	elif InputEventUtils.is_dragged(event, MOUSE_BUTTON_LEFT):
		_press_position += event.relative.abs()
	elif InputEventUtils.is_released(event):
		_press_position = Vector2.ZERO
		
func is_draged() -> bool:
	return _press_position.length() > 10
