class_name ProjectController

signal initialized
signal layer_created(index:int)
signal layer_property_updated(index:int, property:String, value:Variant)
signal layer_deleted(index:int)
signal action_called(action_name:String, data:Dictionary)

var _image_layers: ImageLayers
var _active_layer_index :int = -1

const ACTION_ACTIVATE_LAYER := "ActivateLayer" # {"index":0}
const ACTION_MOVE_LAYER := "MoveLayer" # {"index":0, "to_index":0}
const ACTION_UPDATE_LAYER := "UpdateLayer" # {"index":0}

# NOTE: action_ 开头的方法必须内部包含undo_redo的处理

## Actions ------------------------------------------------------------------------------------------------
func action_init_with(image_layers:ImageLayers):
	set_image_layers(image_layers)
	SystemManager.undoredo_system.clear()

func request_action(action_name:String, data:Dictionary):
	match action_name:
		ACTION_ACTIVATE_LAYER:
			var do_index = data.get("index", 0)
			var undo_index = get_active_layer_index()
			set_active_layer(do_index)
			SystemManager.undoredo_system.add_simple_undoredo(action_name, func(undoredo:UndoRedo):
				undoredo.add_do_method(set_active_layer.bind(do_index))
				undoredo.add_undo_method(set_active_layer.bind(undo_index))
			)
			
		ACTION_MOVE_LAYER:
			var index = data.get("index",0)
			var to_index = data.get("to_index",0)
			move_layer(index, to_index)
			SystemManager.undoredo_system.add_simple_undoredo(action_name, func(undoredo:UndoRedo):
				undoredo.add_do_method(move_layer.bind(index, to_index))
				undoredo.add_undo_method(move_layer.bind(to_index, index))
			)
				
func action_create_layer(index:int):
	if not create_layer(index):
		return 
	SystemManager.undoredo_system.add_simple_undoredo("CreateLayer", func(undoredo:UndoRedo):
		undoredo.add_do_method(create_layer.bind(index))
		undoredo.add_undo_method(delete_layer.bind(index))
	)

func action_delete_layer(index:int):
	var image_layer = _image_layers.get_layer(index)
	if not image_layer:
		return 
	if _image_layers.is_init_state():
		return 
	var is_last = bool(_image_layers.get_layer_count() == 1)		
	if not delete_layer(index):
		return
	if is_last:
		create_layer(0)
		var empty_layer = ImageLayer.create_with(_image_layers.get_size())
		SystemManager.undoredo_system.add_simple_undoredo("DeleteLayer", func(undoredo:UndoRedo):
			undoredo.add_do_method(set_layer.bind(index, empty_layer))
			undoredo.add_undo_method(set_layer.bind(index, image_layer))
		)
	else:
		SystemManager.undoredo_system.add_simple_undoredo("DeleteLayer", func(undoredo:UndoRedo):
			undoredo.add_do_method(delete_layer.bind(index))
			undoredo.add_undo_method(create_layer.bind(index))
			undoredo.add_undo_method(set_layer.bind(index, image_layer))
		)
		
func action_update_layer_property(index:int, property:String, value:Variant, undo_value:Variant=null):
	if undo_value == null:
		undo_value = _image_layers.get_layer_property(index, property)
	if not update_layer_property(index, property, value):
		return 
	SystemManager.undoredo_system.add_simple_undoredo("LayerPropertyUpdated", func(undoredo:UndoRedo):
		undoredo.add_do_method(update_layer_property.bind(index, property, value))
		undoredo.add_undo_method(update_layer_property.bind(index, property, undo_value))
	)

func action_blit_image(index:int, src:Image, mask:Image, src_rect: Rect2i, dst:Vector2i, undo_image_layer:ImageLayer, mode:=ImageLayers.BlitMode.BLIT):
	if not blit_image(index, src, mask, src_rect, dst, mode):
		return 
	var do_image_layer = _image_layers.get_layer(index).duplicate(true)
	SystemManager.undoredo_system.add_simple_undoredo("BlitImage", func(undoredo:UndoRedo):
		undoredo.add_do_method(func():
			set_layer(index, do_image_layer)
		)
		undoredo.add_undo_method(func():
			set_layer(index, undo_image_layer)
		)
	)
	

## Method ------------------------------------------------------------------------------------------------
func create_layer(index:int) -> bool:
	if not _image_layers.create_layer(index):
		return false
	layer_created.emit(index)
	set_active_layer(index)
	return true

func delete_layer(index:int) -> bool:
	if not _image_layers.delete_layer(index):
		return false
	layer_deleted.emit(index)
	_validate_active_index()
	return true

func set_layer(index:int, image_layer:ImageLayer):
	_image_layers.set_layer(index, image_layer)
	update_layer_property(index, ImageLayer.PROP_ALL, image_layer, true)
	
func get_image_layers() -> ImageLayers:
	return _image_layers

func set_image_layers(image_layers:ImageLayers):
	_image_layers = image_layers
	_active_layer_index = _image_layers.get_layer_count()-1
	initialized.emit()
	
func set_active_layer(index:int=0):
	_active_layer_index = index
	raise_action(ACTION_ACTIVATE_LAYER, {"index":_active_layer_index})

func get_active_layer_index() -> int:
	return _active_layer_index

func move_layer(index:int, to_index:int) -> bool:
	if not _image_layers.move_layer(index, to_index):
		return false
	raise_action(ACTION_MOVE_LAYER, {"index":index, "to_index":to_index})
	set_active_layer(to_index)
	return true

func update_layer_property(index:int, property:String, value:Variant, force_update:=false) -> bool:
	if not force_update and _image_layers.get_layer_property(index, property) == value:
		return false
	_image_layers.set_layer_property(index, property, value)
	layer_property_updated.emit(index, property, value)
	return true
	
func blit_image(index:int, src:Image, mask:Image, src_rect: Rect2i, dst:Vector2i, mode:=ImageLayers.BlitMode.BLIT) -> bool:
	if not _image_layers.blit_image(index, src, mask, src_rect, dst, mode):
		return false
	var layer_image = _image_layers.get_layer(index)
	update_layer_property(index, ImageLayer.PROP_IMAGE, layer_image.image, true)
	update_layer_property(index, ImageLayer.PROP_POSITION, layer_image.position, true)
	return true



## Utils ------------------------------------------------------------------------------------------------
func raise_action(action_name:String, data:Dictionary={}):
	action_called.emit(action_name, data)

func _validate_active_index():
	var layers_count = _image_layers.get_layer_count()
	var active_index = _active_layer_index
	if not layers_count:
		active_index = -1
	if active_index >= layers_count:
		active_index = layers_count -1
	set_active_layer(active_index)
