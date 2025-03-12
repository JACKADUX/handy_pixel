class_name ProjectController

signal initialized
signal layer_created(index:int)
signal layer_property_updated(index:int, property:String, value:Variant)
signal layer_deleted(index:int)
signal action_called(action_name:String, data:Dictionary)

var _image_layers: ImageLayers
var _active_layer_index :int = -1

var _action_name := ""

const ACTION_ACTIVATE_LAYER := "ActivateLayer" # {"index":0}
const ACTION_MOVE_LAYER := "MoveLayer" # {"index":0, "to_index":0}

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
			

## Actions BiltImage -------------------------------------------------------------------------------
func action_blit_image_start():
	# NOTE:保证每次action名称不一样
	_action_name = "BiltImage::"+str(Engine.get_process_frames())
	SystemManager.undoredo_system.start_mergends_action(_action_name)

func action_blit_image(image:Image, mask:Image, dst:Vector2i):
	# FIXME: 这个undoredo merge的时机不稳定，
	var layer_image = _image_layers.get_layer(_active_layer_index).image
	var undo_image = layer_image.duplicate()
	layer_image.blit_rect_mask(image, mask, Rect2(Vector2.ZERO, image.get_size()), dst)
	update_layer_property(_active_layer_index, ImageLayer.PROP_IMAGE, layer_image, true)
	
	var do_image = layer_image.duplicate() 
	var rect = Rect2(Vector2.ZERO, layer_image.get_size())
	SystemManager.undoredo_system.add_mergends_action(_action_name, func(undoredo:UndoRedo):
		undoredo.add_do_method(func():
			layer_image.blit_rect(do_image, rect, Vector2.ZERO)
			update_layer_property(_active_layer_index, ImageLayer.PROP_IMAGE, layer_image, true)
		)
		undoredo.add_undo_method(func():
			layer_image.blit_rect(undo_image, rect, Vector2.ZERO)
			update_layer_property(_active_layer_index, ImageLayer.PROP_IMAGE, layer_image, true)
		)
	)

func action_blit_image_end():
	SystemManager.undoredo_system.end_mergends_action()

## Actions Create&Delete Layer ---------------------------------------------------------------------
func action_create_layer(index:int):
	if not create_layer(index):
		return 
	SystemManager.undoredo_system.add_simple_undoredo("CreateLayer", func(undoredo:UndoRedo):
		undoredo.add_do_method(create_layer.bind(index))
		undoredo.add_undo_method(delete_layer.bind(index))
	)

func action_delete_layer(index:int):
	if not delete_layer(index):
		return
	SystemManager.undoredo_system.add_simple_undoredo("DeleteLayer", func(undoredo:UndoRedo):
		undoredo.add_do_method(delete_layer.bind(index))
		undoredo.add_undo_method(create_layer.bind(index))
	)
	
## Actions Update Layer Property---------------------------------------------------------------------
func action_update_layer_property(index:int, property:String, value:Variant):
	var undo_value = _image_layers.get_layer_property(index, property)
	if not update_layer_property(index, property, value):
		return 
	SystemManager.undoredo_system.add_simple_undoredo("LayerPropertyUpdated", func(undoredo:UndoRedo):
		undoredo.add_do_method(update_layer_property.bind(index, property, value))
		undoredo.add_undo_method(update_layer_property.bind(index, property, undo_value))
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

func get_active_image() -> Image:
	return  _image_layers.get_layer_image(_active_layer_index)

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
