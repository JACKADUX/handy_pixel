extends Node

@onready var model := SystemManager.ui_system.model_data_mapper


func _ready() -> void:
	get_parent().text = ""
	var cell_pos_floor = Vector2i.ZERO
	model.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_floor":
				get_parent().show()
				var pos = cell_pos_floor + Vector2i.ONE
				get_parent().text = "(%d, %d)"%[pos.x , pos.y]
	)
