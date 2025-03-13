class_name ImageLayer extends Resource

@export var image: Image
@export var visible := true
@export var position := Vector2.ZERO

const PROP_ALL := "__all__"
const PROP_IMAGE := "image"
const PROP_VISIBLE := "visible"
const PROP_POSITION := "position"

static func create_with(image_size:Vector2, visible:=true, position:=Vector2.ZERO) -> ImageLayer:
	var layer = ImageLayer.new()
	layer.image = Image.create_empty(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	layer.visible = visible
	layer.position = position
	return layer
