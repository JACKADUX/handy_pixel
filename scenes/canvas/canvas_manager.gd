class_name CanvasManager extends Node2D


@export var subviewport_container: SubViewportContainer
@export var bg_color := Color.WHITE

@onready var image_layers_canvas: ImageLayersCanvas = %ImageLayersCanvas
@onready var checker_board: Node2D = %CheckerBoard
@onready var grid: Grid = %Grid

func _ready() -> void:
	SystemManager.canvas_system.canvas_manager = self
	
	SystemManager.project_system.project_controller.initialized.connect(func():
		var canvas_system = SystemManager.canvas_system
		var canvas_size = canvas_system.get_canvas_size()
		set_cheker_board(canvas_size, canvas_system.cheker_size * canvas_system.cell_size)
		set_grid(canvas_system.grid_visible, canvas_size, canvas_system.cell_size)
		image_layers_canvas.scale = Vector2.ONE*canvas_system.cell_size
	)
	
func set_cheker_board(canvas_size:Vector2, checker_size:int):
	checker_board.canvas_size = canvas_size
	checker_board.checker_size = checker_size

func set_grid(grid_visible:bool, canvas_size:Vector2, grid_spacing:int):
	grid.grid_enabled = grid_visible
	grid.canvas_size = canvas_size
	grid.grid_spacing = grid_spacing



	
