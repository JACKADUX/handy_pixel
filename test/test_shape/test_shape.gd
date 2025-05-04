extends Control

var rd = RenderingServer.create_local_rendering_device()
@onready var texture_rect: TextureRect = $TextureRect
@onready var spin_box: SpinBox = $SpinBox
@onready var spin_box_2: SpinBox = $SpinBox2
@onready var check_box: CheckBox = $CheckBox


var shape_creater := Ellipse.new()
var outline_creater := Outline.new()

func _ready() -> void:
	shape_creater.set_rd(rd)
	outline_creater.set_rd(rd)
	_update()
	draw_grid_connect(texture_rect)
	
func draw_grid_connect(canvas_node):
	canvas_node.draw.connect(func():
		var lines = []
		for i in range(canvas_node.size.x+1):
			lines.append(Vector2(i, 0))
			lines.append(Vector2(i, canvas_node.size.y))
			
		for i in range(canvas_node.size.y+1):
			lines.append(Vector2(0, i))
			lines.append(Vector2(canvas_node.size.x, i))
		#canvas_node.draw_line(Vector2.ZERO, canvas_node.size, Color.BLACK)
		canvas_node.draw_multiline(lines, Color.BLACK)
		canvas_node.draw_circle(canvas_node.size*0.5, 0.5, Color.BLUE_VIOLET)
	)
	
func _on_spin_box_value_changed(value: float) -> void:
	_update()

func _on_spin_box_2_value_changed(value: float) -> void:
	_update()

func _update():
	var ellipse_data = Ellipse.EllipseData.create(Vector2(spin_box.value,spin_box_2.value), Color.RED)
	var img = shape_creater.compute(ellipse_data)
	if img and check_box.button_pressed:
		var outline_data = Outline.OutlineData.create(img, Color.BLUE)
		img = outline_creater.compute(outline_data)
	if img:
		img = ImageTexture.create_from_image(img)
	texture_rect.texture = img
	texture_rect.queue_redraw()


func _on_check_box_pressed() -> void:
	_update()
