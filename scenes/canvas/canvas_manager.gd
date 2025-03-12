class_name CanvasManager extends Node2D


@export var subviewport_container: SubViewportContainer

@onready var checker_board: Node2D = %CheckerBoard
@onready var grid: Grid = %Grid


func _ready() -> void:
	SystemManager.canvas_system.canvas_manager = self	
	
	SystemManager.ui_system.model_data_mapper.property_updated.connect(func(prop_name:String, value):
		match prop_name:
			"grid_visible":
				grid.grid_enabled = value
			"checker_size":	
				checker_board.checker_size = value * SystemManager.canvas_system.cell_size
	)
	
func initialize(canvas_size):
	checker_board.canvas_size = canvas_size
	checker_board.checker_size = SystemManager.canvas_system.cheker_size * SystemManager.canvas_system.cell_size
	grid.grid_enabled = SystemManager.canvas_system.grid_visible
	grid.canvas_size = canvas_size
	grid.grid_spacing = SystemManager.canvas_system.cell_size
	#SystemManager.tool_system.camera_tool.center_view(subviewport_container.size)
	

	
