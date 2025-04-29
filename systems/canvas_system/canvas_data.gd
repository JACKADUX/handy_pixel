class_name CanvasData extends Resource

const CELL_SIZE :int = 10 # 像素的放大倍数
@export var viewport_size:Vector2  # 包含画布视图的尺寸
@export var real_canvas_size:Vector2  # 画布的尺寸
@export var camera_offset:Vector2
@export var camera_zoom:float=1

func get_zoomed_canvas_size() -> Vector2:
	# NOTE: 这个尺寸是canvas在视图中所显示的大小
	return real_canvas_size*CELL_SIZE*camera_zoom

func get_canvas_size() -> Vector2:
	# NOTE: 这个尺寸是canvas在画布中所显示的大小
	return real_canvas_size*CELL_SIZE
