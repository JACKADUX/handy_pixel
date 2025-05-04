class_name EraserTool extends PencilTool

const ACTION_ERASE_COLOR := "action_erase_color"

static func get_tool_name() -> String:
	return "eraser"

func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_ERASE_COLOR)
