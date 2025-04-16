extends Node2D

@export_category("Checkerboard Settings")

## 是否启用棋盘格
@export var checkerboard_enabled: bool = true:
	set(value):
		checkerboard_enabled = value
		queue_redraw()

## 棋盘格颜色1 (默认浅灰)
@export var color1: Color = Color(0.8, 0.8, 0.8, 1.0):
	set(value):
		color1 = value
		queue_redraw()

## 棋盘格颜色2 (默认深灰)
@export var color2: Color = Color(0.6, 0.6, 0.6, 1.0):
	set(value):
		color2 = value
		queue_redraw()

## 棋盘格大小 (单位：像素)
@export var checker_size: int = 160:
	set(value):
		checker_size = max(1, value)
		queue_redraw()

## 画布尺寸 (单位：像素)
@export var canvas_size: Vector2 = Vector2(320, 320):
	set(value):
		canvas_size = value
		queue_redraw()

		
func _draw():

	if !checkerboard_enabled:
		return
	
	# 计算棋盘格行列数
	var cols = int(ceil(canvas_size.x / checker_size))
	var rows = int(ceil(canvas_size.y / checker_size))
	
	# 绘制棋盘格
	var rect = Rect2(
			Vector2.ZERO,
			Vector2.ONE * checker_size
		)
	var canvas_rect = Rect2(Vector2.ZERO, canvas_size)
	for y in range(rows):
		for x in range(cols):
			rect.position = Vector2(x,y) * checker_size
			var color = color1 if (x + y) % 2 == 0 else color2
			# FIXME: 这里应该可以通过提前检测优化是否需要intersection
			draw_rect(canvas_rect.intersection(rect), color)
