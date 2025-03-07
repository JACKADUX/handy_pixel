class_name ToolDataController extends Node

@export var view:Node
@export var tool_name := ""
@export var prop_name:String = ""

func _ready() -> void:
	if not view:
		view = get_parent()
		
	SystemManager.tool_system.tool_registered.connect(func(_tool_name:String):
		if _tool_name != tool_name:
			return 
		var model = SystemManager.tool_system.get_tool(tool_name)
		if not model:
			push_error(self, " 工具不存在:", tool_name)
			return 
		GeneralController.bind_view_model(view, model, prop_name)
	)
	
