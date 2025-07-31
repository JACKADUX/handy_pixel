class_name ImageLayer extends Resource

@export var image: Image
@export var visible := true
@export var position := Vector2i.ZERO
@export var opacity :float = 1
@export var lock := false

const PROP_ALL := "__all__"
const PROP_IMAGE := "image"
const PROP_VISIBLE := "visible"
const PROP_POSITION := "position"
const PROP_OPACITY := "opacity"
const PROP_LOCK := "lock"

func update_with(image_layer:ImageLayer):
	image = image_layer.image.duplicate() if image_layer.image else null
	visible = image_layer.visible
	position = image_layer.position
	opacity = image_layer.opacity
	lock = image_layer.lock
	
static func create_with(image_size:=Vector2.ZERO, p_visible:=true, p_position:=Vector2.ZERO) -> ImageLayer:
	var layer = ImageLayer.new()
	if image_size.x > 0 and image_size.y > 0:
		layer.image = Image.create_empty(int(image_size.x), int(image_size.y), false, Image.FORMAT_RGBA8)
	layer.visible = p_visible
	layer.position = p_position
	return layer

static func create_with_image(p_image:Image, p_visible:=true, p_position:=Vector2.ZERO) -> ImageLayer:
	p_image.convert(Image.FORMAT_RGBA8)
	var layer = ImageLayer.new()
	layer.image = p_image
	layer.visible = p_visible
	layer.position = p_position
	return layer
