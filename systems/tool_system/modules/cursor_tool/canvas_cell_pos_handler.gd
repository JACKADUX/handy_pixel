extends Node
var dlg
func _ready() -> void:
	dlg = get_parent()
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	SystemManager.tool_system.cursor_tool.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"cell_pos_floor":
				dlg.show()
				var pos = value + Vector2i.ONE
				dlg.set_tooltip("","x:%d  |  y:%d"%[pos.x , pos.y])
				dlg.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
				dlg.tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	)
	if not dlg.is_node_ready():
		await dlg.ready
	dlg.hide()
	dlg.tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
