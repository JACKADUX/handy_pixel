extends Node

const SPEED_25 = preload("res://assets/icons/speed_0_25_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const SPEED_50 = preload("res://assets/icons/speed_0_5_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const SPEED_75 = preload("res://assets/icons/speed_0_75_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const SPEED_100= preload("res://assets/icons/speed_1x_mobiledata_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")

const icons = [SPEED_25, SPEED_50, SPEED_75, SPEED_100]

func _ready() -> void:
	
	await SystemManager.system_initialized
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cursor_speed_factor":
				var index = floor(value*icons.size()) -1
				get_parent().icon = icons[int(index)]
	)
	
	var index = floor(SystemManager.tool_system.cursor_tool.cursor_speed_factor*icons.size()) -1
	get_parent().icon = icons[int(index)]
