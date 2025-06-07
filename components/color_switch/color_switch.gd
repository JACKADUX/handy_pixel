extends VBoxContainer

signal confirmed
signal canceled

@onready var ori_texture_rect: TextureRect = %OriTextureRect
@onready var result_texture_rect: TextureRect = %TextureRect

@onready var confirm_dialog: PanelContainer = %ConfirmDialog

@onready var color_palette_generator: ColorPaletteGenerator = %ColorPaletteGenerator
@onready var color_selection_button = %ColorSelectionButton

@export var max_color_count :int=128
@onready var info_label: Label = %InfoLabel

var image :Image
var result_image :Image

var cso_color_select : ComputeShaderSystem.ColorSelect

var target_color := Color.RED
var active_color := Color.GREEN

func debug():
	var rd := RenderingServer.create_local_rendering_device()
	const TXTURE = preload("res://logo.png")
	image = TXTURE.get_image()

	cso_color_select = ComputeShaderSystem.ColorSelect.new()
	cso_color_select.set_rd(rd)

	init_with(image, active_color)
	
func _ready() -> void:
	confirm_dialog.confirmed.connect(func():
		confirmed.emit()
	)
	confirm_dialog.canceled.connect(func():
		canceled.emit()
	)
	
	color_palette_generator.color_selected.connect(func(value):
		target_color = value
		generate()
	)
	
	color_selection_button.value_changed.connect(func(value):
		set_color(value)
		generate()
	)
	#debug()
	#generate()
	
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	cso_color_select = SystemManager.compute_shader_system.get_compute_shader_object("color_select")


func init_with(input_image:Image, color:Color):
	image = input_image
	set_color(color)
	extrac_colors()
	generate()

func extrac_colors():
	info_label.hide()
	var palette = ColorPalette.new()
	if image:
		var colors_data := {}
		var image_size = image.get_size()
		var step_x = 1
		var step_y = 1
		if image_size.x > 1024:
			step_x = 2
		elif image_size.x > 2048:
			step_x = 4
		if image_size.y > 1024:
			step_y = 2
		elif image_size.y > 2048:
			step_y = 4
		var active_in_colors = false
		for x in range(0, image_size.x, step_x):
			for y in range(0, image_size.y, step_y):
				var color = image.get_pixel(x, y)
				if color.a == 0:
					continue
				colors_data[color] = 1 
				if not active_in_colors and active_color == color:
					active_in_colors = true
		var colors = colors_data.keys()
		var color_count = colors.size()
		var ori_count = color_count
		while max_color_count < color_count:
			colors = colors.slice(0, color_count, 2)
			color_count = colors.size()
				
		if active_in_colors :
			if active_color not in colors:
				colors.insert(0, active_color)
			target_color = active_color
		var final_count = colors.size()
		palette.colors = colors
		
		if ori_count != final_count:
			info_label.show()
			info_label.text = "%d -> %d"%[ori_count, final_count]
			
	color_palette_generator.generate(palette)
	color_palette_generator.activate_color(active_color)
	
func generate():
	result_image = null
	ori_texture_rect.texture = ImageTexture.create_from_image(image)
	var color_select_image = cso_color_select.compute(cso_color_select.ColorSelectData.create(image, target_color))
	if color_select_image:
		result_image = _apply_color(color_select_image, active_color)
		result_texture_rect.texture = ImageTexture.create_from_image(result_image)
	else:
		result_texture_rect.texture = null

func get_result_image() -> Image:
	return result_image

func set_color(value:Color):
	active_color = value
	color_selection_button.set_value(value)
	
func _apply_color(image:Image, color:Color) -> Image:
	var empty_image :Image = image.duplicate()
	empty_image.fill(Color.TRANSPARENT)
	var color_image :Image = image.duplicate()
	color_image.fill(color)
	empty_image.blit_rect_mask(color_image, image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO)
	return empty_image
