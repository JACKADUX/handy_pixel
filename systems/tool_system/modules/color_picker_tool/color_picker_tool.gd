class_name ColorPickerTool extends BaseTool

const ACTION_PICK_COLOR := "action_pick_color"

static func get_tool_name() -> String:
	return "color_picker"


func pick_color(pos:Vector2) -> Color:
	var image_layers := project_controller.get_image_layers()
	return image_layers.get_pixel(pos)
