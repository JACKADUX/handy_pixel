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
	
static func create_with(image_size:=Vector2.ZERO, visible:=true, position:=Vector2.ZERO) -> ImageLayer:
	var layer = ImageLayer.new()
	if image_size.x > 0 and image_size.y > 0:
		layer.image = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	layer.visible = visible
	layer.position = position
	return layer

static func create_with_image(image:Image, visible:=true, position:=Vector2.ZERO) -> ImageLayer:
	var layer = ImageLayer.new()
	image.convert(Image.FORMAT_RGBA8)
	layer.image = image
	layer.visible = visible
	layer.position = position
	return layer
