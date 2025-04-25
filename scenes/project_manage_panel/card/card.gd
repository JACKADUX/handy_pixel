extends PanelContainer

@onready var main_button: Button = %Button
@onready var texture_rect: TextureRect = %TextureRect

@onready var margin_container: MarginContainer = %MarginContainer

@onready var delete_button: Button = %DeleteButton
@onready var export_button: Button = %ExportButton
@onready var buttons_container: HBoxContainer = %ButtonsContainer

func set_margin(value:int):
	margin_container.add_theme_constant_override("margin_left", value)
	margin_container.add_theme_constant_override("margin_right", value)
	margin_container.add_theme_constant_override("margin_top", value)
	margin_container.add_theme_constant_override("margin_bottom", value)
	
