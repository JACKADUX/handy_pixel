extends PanelContainer

signal new_layer_requested(at_index:int)
signal update_layer_property_requested(index:int, property:String, value:Variant)
signal delete_layer_requested(index:int)
signal move_layer_requested(index:int, to_index:int)
signal activate_layer_requested(index:int)

@onready var container_agent: ContainerAgent = %ContainerAgent
@onready var add_layer_button: Button = %AddLayerButton
@onready var delete_button: Button = %DeleteButton
@onready var move_up_button: Button = %MoveUpButton
@onready var move_down_button: Button = %MoveDownButton

@onready var widget_layer_opacity: = %WidgetLayerOpacity

const Layer = preload("res://scenes/ui/image_layers_ui/layer.gd")
const LAYER = preload("res://scenes/ui/image_layers_ui/layer.tscn")

# NOTE: active_index 是数据图层的序号，不是控件的序号
#	    数据图层的序号和控件序号刚好相反
var active_index := -1
	
func _ready() -> void:
	add_layer_button.pressed.connect(func():
		new_layer_requested.emit(active_index+1)
	)
	
	delete_button.pressed.connect(func():
		delete_layer_requested.emit(active_index)
	)
	
	move_up_button.pressed.connect(func():
		move_layer_requested.emit(active_index, active_index+1)
	)
	move_down_button.pressed.connect(func():
		move_layer_requested.emit(active_index, active_index-1)
	)
	
	widget_layer_opacity.value_changed.connect(func(value:float):
		update_layer_property_requested.emit(active_index, ImageLayer.PROP_OPACITY, value)
	)
	
	bind_with_controller(SystemManager.project_system.project_controller)


func bind_with_controller(project_contorller :ProjectController):
	project_contorller.initialized.connect(func():
		var layers := project_contorller.get_image_layers().get_layers()
		init_with(layers, project_contorller.get_active_layer_index())
		
	)
	project_contorller.layer_created.connect(func(index:int):
		var layer = create_layer()
		move_layer(layer, index)
		update_layers_index()
		var layers := project_contorller.get_image_layers().get_layers()
		update_layer_with(layer, layers[index])
	)
	
	project_contorller.layer_deleted.connect(func(index:int):
		delete_layer(get_layer(index))
		update_layers_index()
	)
	
	project_contorller.action_called.connect(func(action_name:String, data:Dictionary):
		match action_name:
			ProjectController.ACTION_ACTIVATE_LAYER:
				var index = data.get("index", 0)
				if index == -1:
					printerr("ProjectController.ACTION_ACTIVATE_LAYER: index == -1")
					return 
				set_active_index(index)
				var layers := project_contorller.get_image_layers().get_layers()
				update_side_property_with(layers[index])
				
			ProjectController.ACTION_MOVE_LAYER:
				var index = data.get("index", 0)
				var to_index = data.get("to_index", 0)
				move_layer(get_layer(index), to_index)
				update_layers_index()
	)
	
	project_contorller.layer_property_updated.connect(func(index:int, property:String, value:Variant):
		var layer = get_layer(index)
		match property:
			ImageLayer.PROP_IMAGE:
				update_layer_texture(layer, value)
			ImageLayer.PROP_VISIBLE:
				set_layer_visible(layer, value)
			ImageLayer.PROP_OPACITY:
				set_layer_opacity(layer, value)
			ImageLayer.PROP_LOCK:
				set_layer_locked(layer, value)
			ImageLayer.PROP_ALL:
				update_layer_with(layer, value)
		if index == active_index:
			var layers := project_contorller.get_image_layers().get_layers()
			update_side_property_with(layers[index])
	)
	
	## inner
	new_layer_requested.connect(func(at_index:int):
		project_contorller.action_create_layer(at_index)
	)
	
	delete_layer_requested.connect(func(index:int):
		project_contorller.action_delete_layer(index)
	)
	
	activate_layer_requested.connect(func(index:int):
		project_contorller.request_action(ProjectController.ACTION_ACTIVATE_LAYER, {"index": index})
	)
	
	update_layer_property_requested.connect(func(index:int, property:String, value:Variant):
		project_contorller.action_update_layer_property(index, property, value)
	)
	move_layer_requested.connect(func(index:int, to_index:int):
		project_contorller.request_action(ProjectController.ACTION_MOVE_LAYER, {"index":index, "to_index":to_index})
	)
	
	
func init_with(layers:Array[ImageLayer], active_index:int=0):
	clear()
	for image_layer:ImageLayer in layers:
		update_layer_with(create_layer(), image_layer)
	update_layers_index()
	set_active_index(active_index) # 
	update_side_property_with(layers[active_index])

	
func update_layer_with(layer:Layer, image_layer:ImageLayer):
	set_layer_visible(layer, image_layer.visible)
	set_layer_opacity(layer, image_layer.opacity)
	set_layer_locked(layer, image_layer.lock)
	update_layer_texture(layer, image_layer.image)

func clear():
	container_agent.clear()

func set_active_index(index:int):
	active_index = index
	update_layers_activate()
	var active_layer = get_layer(active_index)
	ensure_layer_control_visible(get_layer(active_index))

func update_side_property_with(image_layer:ImageLayer):
	widget_layer_opacity.set_value(image_layer.opacity)
	
func get_layers() -> Array:
	return container_agent.get_items()

func create_layer() -> Layer:
	var layer = LAYER.instantiate()
	container_agent.add_item(layer)
	container_agent.move_item(layer, 0)
	layer.visible_button.toggled.connect(_on_layer_visible_pressed.bind(layer))
	layer.fake_button.pressed.connect(_on_layer_activate_pressed.bind(layer))
	layer.lock_button.toggled.connect(_on_layer_lock_pressed.bind(layer))
	return layer

func ensure_layer_control_visible(layer:Layer):
	if not layer:
		return 
	await get_tree().process_frame
	container_agent.get_parent().ensure_control_visible(layer)

func get_layer(index:int) -> Layer:
	# NOTE: index 是数据图层的序号，不是控件的序号
	var layers = get_layers()
	var layers_count = layers.size()
	var layer_index = layers_count-index-1
	if layer_index < 0 or layers_count <= layer_index:
		return 
	return layers[layer_index]

func get_layer_index(layer:Layer)->int:
	return get_layers().size() -layer.get_index() -1

func delete_layer(layer:Layer):
	if not layer:
		return 
	container_agent.remove_item(layer)

func move_layer(layer:Layer, to_index:int):
	if not layer:
		return 
	var layers = get_layers()
	var layers_count = layers.size()
	var layer_index = layers_count-to_index-1
	container_agent.move_item(layer, layer_index)

func set_layer_visible(layer:Layer, value:bool):
	layer.visible_button.set_pressed_no_signal(value)
	layer.visible_button.self_modulate.a = 0.3 if not value else 1.

func set_layer_opacity(layer:Layer, value:float):
	layer.cover.self_modulate.a = value
	layer.opacity_label.visible = bool(value != 1)
	layer.opacity_label.text = "%0.0f%%"%(value*100)
	
func set_layer_locked(layer:Layer, value:bool):
	layer.lock_button.set_pressed_no_signal(value)
	layer.lock_button.self_modulate.a = 0.3 if not value else 1.

func update_layer_texture(layer:Layer, image:Image):
	if not image:
		layer.cover.texture = null
		return
	var texture = layer.cover.texture
	if not texture:
		texture = ImageTexture.create_from_image(image)
		layer.cover.texture = texture
	elif texture.get_size() != Vector2(image.get_size()):
		texture.set_image(image)
	else:
		texture.update(image)
		
func update_layers_index():
	var layers = get_layers()
	var layers_count = layers.size()
	for layer:Layer in layers:
		layer.index_label.text = str(layers_count - layer.get_index())
		
func update_layers_activate():
	var layers = get_layers()
	var layers_count = layers.size()
	for layer:Layer in layers:
		var layer_index = layers_count-layer.get_index()-1
		layer.active_panel.visible = layer_index == active_index

func _on_layer_visible_pressed(toggle_on:bool, layer:Layer):
	var index = get_layer_index(layer)
	update_layer_property_requested.emit(index, ImageLayer.PROP_VISIBLE, toggle_on)
	
func _on_layer_activate_pressed(layer:Layer):
	var index = get_layer_index(layer)
	activate_layer_requested.emit(index)

func _on_layer_lock_pressed(toggle_on:bool, layer:Layer):
	var index = get_layer_index(layer)
	update_layer_property_requested.emit(index, ImageLayer.PROP_LOCK, toggle_on)
