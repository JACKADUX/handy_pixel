extends PanelContainer

@onready var texture_rect_opacity: TextureRect = %TextureRectOpacity
@onready var texture_rect_lock: TextureRect = %TextureRectLock
@onready var texture_rect_visible: TextureRect = %TextureRectVisible

@export var index_lable : Label

func _ready() -> void:
	var project_contorller = SystemManager.project_system.project_controller
	
	project_contorller.initialized.connect(func():
		update()
	)
	
	project_contorller.action_called.connect(func(action_name:String, data:Dictionary):
		match action_name:
			ProjectController.ACTION_ACTIVATE_LAYER:
				update()
	)
	project_contorller.layer_property_updated.connect(func(index:int, property:String, value:Variant):
		var active_index = project_contorller.get_active_layer_index()
		if index != active_index or active_index < 0:
			return 
		update()
	)

func update():
	var project_contorller = SystemManager.project_system.project_controller
	var active_index = project_contorller.get_active_layer_index()
	if active_index < 0:
		return 
	var image_layers = project_contorller.get_image_layers()
	texture_rect_lock.visible = image_layers.get_layer_property(active_index, ImageLayer.PROP_LOCK)
	texture_rect_opacity.visible = image_layers.get_layer_property(active_index, ImageLayer.PROP_OPACITY) != 1
	texture_rect_visible.visible = not image_layers.get_layer_property(active_index, ImageLayer.PROP_VISIBLE)
	visible = (
		texture_rect_lock.visible
		or texture_rect_opacity.visible
		or texture_rect_visible.visible
	)
	index_lable.text = str(active_index+1)
	
