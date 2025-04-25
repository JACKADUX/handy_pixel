extends Control

var rd := RenderingServer.create_local_rendering_device()

@onready var texture_rect: TextureRect = $TextureRect
@onready var texture_rect_2: TextureRect = $TextureRect2
@onready var texture_rect_3: TextureRect = $TextureRect3

var image:Image 
var image2:Image 

var test_color_select

const LOGO = preload("res://logo.png")

var scanline_fill = ScanlineFill.new()
var floor_fill := FloodFill.new()

var local = Vector2(2956.0, 1688.0)
@onready var spin_box: SpinBox = $SpinBox

var tolarence = 0
@onready var label: Label = $Label
@onready var label_3: Label = $Label3
@onready var label_4: Label = $Label4
@onready var label_2: Label = $Label2

func _ready() -> void:
	image = LOGO.get_image()
	_on_button_pressed()
	floor_fill.set_rd(rd)
	
func _on_button_pressed() -> void:
	var mul = 16#16
	image = image.duplicate()
	#image.flip_x()
	image.resize(512*mul,512*mul,Image.INTERPOLATE_NEAREST)  
	texture_rect.texture.set_image(image)

func _on_spin_box_value_changed(value: float) -> void:
	var bs = Benchmark.start()
	var output_image = floor_fill.compute(image, local, Color.RED, tolarence, value)
	if output_image:
		texture_rect_2.texture.set_image(output_image)
	Benchmark.end(bs)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = texture_rect.get_local_mouse_position()
		local = pos* float(image.get_width())/texture_rect.size.x
		label.text = "img_size: %d x %d "%[image.get_width(), image.get_height()] 
		var bs = Benchmark.start()
		var output_image = floor_fill.compute(image, local, Color.RED, tolarence, spin_box.value)
		if output_image:
			texture_rect_3.texture.set_image(output_image)
		var text1 = Benchmark.end(bs)
		label_3.text = "GPU :"+ "time_cost: "+str(text1) +" ms "
		
		#bs = Benchmark.start()
		#output_image = floor_fill.floor_fill_cpu(image, local, Color.RED, tolarence, spin_box.value)
		#if output_image:
			#texture_rect_2.texture.set_image(output_image)
		#var text2 = Benchmark.end(bs)
		#label_4.text = "CPU :"+ "time_cost: "+str(text2) +" ms "
		#label_2.text = "GPU:CPU = %.02f : %.02f"%[1, float(text2)/text1]
		
		
