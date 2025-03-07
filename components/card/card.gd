class_name Card extends Button

@onready var texture_rect: TextureRect = %TextureRect

@onready var margin_container: MarginContainer = $MarginContainer



func set_margin(value:int):
	margin_container.add_theme_constant_override("margin_left", value)
	margin_container.add_theme_constant_override("margin_right", value)
	margin_container.add_theme_constant_override("margin_top", value)
	margin_container.add_theme_constant_override("margin_bottom", value)
	

const CARD = preload("res://components/card/card.tscn")
static func new_card() -> Card:
	return CARD.instantiate()
