class_name Grid extends Node2D

@export_category("Pixel Grid Settings")

## 是否启用网格显示
@export var grid_enabled: bool = true:
	set(value):
		grid_enabled = value
		queue_redraw()

## 网格颜色
@export var grid_color: Color = Color(0.5, 0.5, 0.5, 0.2):
	set(value):
		grid_color = value
		queue_redraw()

## 网格间隔像素数 (画布实际像素)
@export var grid_spacing: int = 10:
	set(value):
		grid_spacing = max(1, value)
		queue_redraw()

## 网格线宽 (屏幕像素)
@export var line_width: float = -1:
	set(value):
		line_width = value
		queue_redraw()

## 画布尺寸 (单位：像素)
@export var canvas_size: Vector2 = Vector2(320, 320):
	set(value):
		canvas_size = value
		queue_redraw()

func _ready() -> void:
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	SystemManager.tool_system.camera_tool.property_updated.connect(func(prop, value):
		if !grid_enabled:
			return 
		match prop:
			"camera_zoom":
				_update_visible()
	)

func _update_visible():
	hide() if SystemManager.tool_system.camera_tool.camera_zoom <= 1 else show()
	
func _draw():
	if !grid_enabled or grid_spacing < 1:
		return
	_update_visible()
	var lines = PackedVector2Array()
	# 绘制纵向网格线
	for x in range(0, int(canvas_size.x) + 1, grid_spacing):
		var start = Vector2(x, 0)
		var end = Vector2(x, canvas_size.y)
		lines.append(start)
		lines.append(end)
	
	# 绘制横向网格线
	for y in range(0, int(canvas_size.y) + 1, grid_spacing):
		var start = Vector2(0, y)
		var end = Vector2(canvas_size.x, y)
		lines.append(start)
		lines.append(end)
		
	draw_multiline(lines, grid_color, line_width)
	# 绘制外边框
	draw_rect(Rect2(0, 0, canvas_size.x, canvas_size.y), grid_color, false, line_width)
