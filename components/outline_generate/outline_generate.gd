extends VBoxContainer

signal confirmed
signal canceled

@onready var texture_rect: TextureRect = %TextureRect
@onready var outline_texture_rect: TextureRect = %OutlineTextureRect
@onready var custom_spin_box_widget: CustomSpinBoxWidget = %CustomSpinBoxWidget
@onready var grid_container: GridContainer = %GridContainer
@onready var confirm_dialog = %ConfirmDialog
@onready var pattern_view_adapter = %PatternViewAdapter
@onready var color_selection_button = %ColorSelectionButton

var image :Image

var cso_outline : ComputeShaderSystem.Outline

var active_color := Color.GREEN
var expand_size :int:
	set(value):
		custom_spin_box_widget.set_value(value)
	get:
		return custom_spin_box_widget.get_value()
		
var pattern :Array:
	get:
		return pattern_view_adapter.get_value()

var result_image :Image

func debug():
	var rd := RenderingServer.create_local_rendering_device()
	const TXTURE = preload("res://assets/icons/add_box_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")
	image = TXTURE.get_image()

	cso_outline = ComputeShaderSystem.Outline.new()
	cso_outline.set_rd(rd)

func _ready() -> void:
	custom_spin_box_widget.value_changed.connect(func(v):
		generate()
	)
	pattern_view_adapter.value_changed.connect(func(v):
		generate()
	)
	confirm_dialog.confirmed.connect(func():
		confirmed.emit()
	)
	confirm_dialog.canceled.connect(func():
		canceled.emit()
	)
	
	color_selection_button.value_changed.connect(func(value):
		set_color(value)
		generate()
	)
	
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	cso_outline = SystemManager.compute_shader_system.get_compute_shader_object("outline")
	
	#debug()
	#generate()

func get_result_image() -> Image:
	return result_image

func init_with(input_image:Image, color:Color):
	image = input_image
	set_color(color)
	generate()
	
func generate():
	result_image = null
	var expand_image = _expand_image(image, expand_size)
	texture_rect.texture = ImageTexture.create_from_image(expand_image)
	var outline_image = cso_outline.compute(cso_outline.OutlineData.create_with_list(expand_image.duplicate(true), pattern, expand_size))
	if outline_image:
		result_image = _apply_color(outline_image, active_color)
		result_image.blit_rect_mask(expand_image, expand_image, Rect2(Vector2.ZERO, expand_image.get_size()), Vector2.ZERO)
		outline_texture_rect.texture = ImageTexture.create_from_image(result_image)
	else:
		outline_texture_rect.texture = null

func set_color(value:Color):
	active_color = value
	color_selection_button.set_value(value)
	
func _expand_image(image:Image, expand:int=1) -> Image:
	if expand < 1 or not image:
		return image
	var rect = Rect2(Vector2.ZERO, image.get_size())
	var grow_rect = rect.grow(expand)
	var expand_image = Image.create_empty(grow_rect.size.x, grow_rect.size.y, false, Image.FORMAT_RGBA8)
	expand_image.blit_rect(image, rect, Vector2.ONE*expand)
	return expand_image

func _apply_color(image:Image, color:Color) -> Image:
	var empty_image :Image = image.duplicate()
	empty_image.fill(Color.TRANSPARENT)
	var color_image :Image = image.duplicate()
	color_image.fill(color)
	empty_image.blit_rect_mask(color_image, image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO)
	return empty_image
