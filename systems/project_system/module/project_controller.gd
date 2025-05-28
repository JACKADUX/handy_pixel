class_name ProjectController

signal initialized
signal layer_created(index:int)
signal layer_property_updated(index:int, property:String, value:Variant)
signal layer_deleted(index:int)
signal action_called(action_name:String, data:Dictionary)

var _image_layers: ImageLayers
var _active_layer_index :int = -1
var _image_mask := ImageMask.new()
var _copy_data : ImageLayer

const ACTION_ACTIVATE_LAYER := "ActivateLayer" # {"index":0}
const ACTION_MOVE_LAYER := "MoveLayer" # {"index":0, "to_index":0}
const ACTION_UPDATE_LAYER := "UpdateLayer" # {"index":0}

const ACTION_ADD_RECT_IMAGE_MASK := "AddRectImageMask" # {"rect":Rect, "type":mask_type}
const ACTION_IMAGE_MASK_CHANGED := "ImageMaskChanged" # {}
const ACTION_CLEAR_IMAGE_MASK := "ClearImageMask" # {}
const ACTION_IMAGE_MASK_DELETE := "ImageMaskDelete"
const ACTION_IMAGE_MASK_COPY := "ImageMaskCopy"
const ACTION_CLEAR_IMAGE_MASK_COPY_DATA := "ClearImageMaskCopyData"
const ACTION_IMAGE_MASK_PAST := "ImageMaskPaste"
const ACTION_IMAGE_MASK_SELECT_ALL := "ImageMaskSelectAll"

# NOTE: action_ 开头的方法必须内部包含undo_redo的处理

## Actions ------------------------------------------------------------------------------------------------
func action_init_with(image_layers:ImageLayers):
	set_image_layers(image_layers)
	_image_mask.clear()
	_image_mask.set_mask_size(image_layers.get_size())
	raise_action(ACTION_IMAGE_MASK_CHANGED)
	SystemManager.undoredo_system.clear()

func request_action(action_name:String, data:={}):
	match action_name:
		ACTION_ACTIVATE_LAYER:
			var do_index = data.get("index", 0)
			var undo_index = get_active_layer_index() if not data.has("undo_index") else data.get("undo_index")
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
			
		ACTION_ADD_RECT_IMAGE_MASK:
			var rect = data.get("rect", Rect2())
			var mask_type = data.get("mask_type", ImageMask.MaskType.NEW)
			action_update_image_mask(func():
				_image_mask.update_mask_with(rect, mask_type)
			)

		ACTION_CLEAR_IMAGE_MASK:
			if not _image_mask.has_mask():
				return 
			action_update_image_mask(func():
				_image_mask.clear()
			)
		
		ACTION_IMAGE_MASK_DELETE:
			if not _image_mask.has_mask():
				return 
			var active_index = get_active_layer_index()
			var rect = _image_mask.get_used_rect()
			var mask = _image_mask.get_region_mask(rect)
			var src = mask.duplicate() as Image
			src.fill(Color.TRANSPARENT)
			var undo_image_layer = _image_layers.get_layer(active_index).duplicate(true)
			action_blit_image(active_index, 
							src, mask, Rect2(Vector2.ZERO, rect.size), rect.position, 
							undo_image_layer, ImageLayers.BlitMode.BLIT
			)
			
		ACTION_IMAGE_MASK_COPY:
			if not _image_mask.has_mask():
				return 
			var active_index = get_active_layer_index()
			var rect = _image_mask.get_used_rect()
			var mask = _image_mask.get_region_mask(rect)
			var src = mask.duplicate() as Image
			src.fill(Color.TRANSPARENT)
			
			var image = _image_layers.get_canvas_image(active_index)
			if image:
				image = image.get_region(rect)
				src.blit_rect_mask(image, mask, Rect2(Vector2.ZERO, rect.size), Vector2.ZERO)
			if src.is_empty() or src.is_invisible():
				PopupArrowPanelManager.get_from_ui_system().infomation_dialog("复制失败：选区内无有效像素!", Vector2.ZERO)
				return 
			src = src.get_region(src.get_used_rect())
			_copy_data = ImageLayer.create_with_image(src)
			raise_action(ACTION_IMAGE_MASK_COPY)
		
		ACTION_CLEAR_IMAGE_MASK_COPY_DATA:
			_copy_data = null
			raise_action(ACTION_IMAGE_MASK_COPY)
		
		ACTION_IMAGE_MASK_PAST:
			if not _copy_data:
				return 
			SystemManager.undoredo_system.add_simple_undoredo("PasteLayer", func(undoredo:UndoRedo):
				var undo_active_index = get_active_layer_index()
				var index = _image_layers.get_layer_count()
				action_update_image_mask(_image_mask.clear)
				action_create_layer(index)
				request_action(ACTION_ACTIVATE_LAYER, {"index": index, "undo_index": undo_active_index})
				set_layer(index, _copy_data)
				undoredo.add_do_method(set_layer.bind(index, _copy_data.duplicate(true)))
			)
		
		ACTION_IMAGE_MASK_SELECT_ALL:
			action_update_image_mask(func():
				_image_mask.update_mask_with(Rect2(Vector2.ZERO,_image_layers.get_size()))
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
			set_layer_with(index, do_image_layer.image, do_image_layer.position)
		)
		undoredo.add_undo_method(func():
			set_layer_with(index, undo_image_layer.image, undo_image_layer.position)
		)
	)

func action_update_image_mask(update_mask_fn:Callable):
	var undo_image = _image_mask.get_mask()
	update_mask_fn.call()
	var do_image = _image_mask.get_mask()
	action_set_image_mask(do_image, undo_image)
	
func action_set_image_mask(do_image:Image, undo_image:Image):
	_image_mask.set_mask(do_image)
	raise_action(ACTION_IMAGE_MASK_CHANGED)
	SystemManager.undoredo_system.add_simple_undoredo("MaskChanged", 
		func(undoredo:UndoRedo):
			undoredo.add_do_method(func():
				_image_mask.set_mask(do_image)
				raise_action(ACTION_IMAGE_MASK_CHANGED)
			)
			undoredo.add_undo_method(func():
				_image_mask.set_mask(undo_image)
				raise_action(ACTION_IMAGE_MASK_CHANGED)
			)
	)

## ImageLayer Method ------------------------------------------------------------------------------------------------
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
	update_layer_property(index, ImageLayer.PROP_ALL, image_layer, true)

func set_layer_with(index:int, image:Image, position:Vector2i):
	update_layer_property(index, ImageLayer.PROP_IMAGE, image, true)
	update_layer_property(index, ImageLayer.PROP_POSITION, position, true)

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
	if not is_layer_editable(index):
		return false
	mask = _image_mask.intersect_mask(src, mask, src_rect, dst)
	if not _image_layers.blit_image(index, src, mask, src_rect, dst, mode):
		return false
	var layer_image = _image_layers.get_layer(index)
	set_layer_with(index, layer_image.image, layer_image.position)
	return true

func is_layer_editable(index:int) -> bool:
	return not _image_layers.get_layer_property(index, ImageLayer.PROP_LOCK)

## ImageMask Method ------------------------------------------------------------------------------------------------
func get_image_mask() -> ImageMask:
	return _image_mask



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
