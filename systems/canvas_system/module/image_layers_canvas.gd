class_name ImageLayersCanvas extends Node2D

var viewport_id :RID  = RenderingServer.viewport_create()
var viewport_canvas_id :RID  = RenderingServer.canvas_create()
var canvas_id :RID  = RenderingServer.canvas_item_create() 

var _prev_size := Vector2.ZERO

var textures : Array[ImageTexture] = []
var rids :Array[RID] = []

var _redraw_dirty := []

var canvas_size = Vector2(32, 32)

var _debug_mode := false

func _ready() -> void:
	init_viewport()
	#_debug()
	
func _debug():
	scale = Vector2.ONE*10
	set_viewport_size(canvas_size)
	var image = Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.AQUA)
	create_layer(0, image)
	
	image = Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.FIREBRICK)
	create_layer(1, image)
	#set_layer_visible(1, false)
	set_layer_position(1, Vector2(4,6))
	queue_redraw_layer.call_deferred(-1)
	
func _process(delta: float) -> void:
	if _redraw_dirty:
		for index in _redraw_dirty:
			draw_layer(index)
		_redraw_dirty = []
		queue_redraw()
		
		

func bind_with_controller():
	var project_contorller:ProjectController = SystemManager.project_system.project_controller
	project_contorller.initialized.connect(func():
		init_with(project_contorller.get_image_layers())
	)
	
	project_contorller.layer_created.connect(func(index:int):
		var image_layers := project_contorller.get_image_layers()
		var image_layer = image_layers.get_layer(index)
		create_layer(index, image_layer.image)
	)
	
	project_contorller.layer_deleted.connect(func(index:int):
		delete_layer(index)
	)
	
	project_contorller.action_called.connect(func(action_name:String, data:Dictionary):
		match action_name:
			ProjectController.ACTION_ACTIVATE_LAYER:
				# TODO: 也许可以强化展示当前激活的图层
				pass
			ProjectController.ACTION_MOVE_LAYER:
				var index = data.get("index", 0)
				var to_index = data.get("to_index", 0)
				var image_layers := project_contorller.get_image_layers()
				update_layer_with(index, image_layers.get_layer(index))
				update_layer_with(to_index, image_layers.get_layer(to_index))
	)
	project_contorller.layer_property_updated.connect(func(index:int, property:String, value:Variant):
		var image_layer := project_contorller.get_image_layers().get_layer(index)
		match property:
			ImageLayer.PROP_ALL:
				update_layer_with(index, value)
			ImageLayer.PROP_IMAGE:
				update_layer_texture(index, value)
			ImageLayer.PROP_VISIBLE:
				set_layer_visible(index, value)
			ImageLayer.PROP_POSITION:
				set_layer_position(index, value)
	)
	
func init_with(image_layers:ImageLayers):
	clear()
	canvas_size = image_layers.get_size()
	set_viewport_size(canvas_size)
	for index in image_layers.get_layer_count():
		var image_layer = image_layers.get_layer(index)
		create_layer(index, image_layer.image)
		update_layer_with(index, image_layer)
	queue_redraw_layer(-1)
	
func update_layer_with(index:int, image_layer:ImageLayer):
	update_layer_texture(index, image_layer.image)
	set_layer_visible(index, image_layer.visible)
	set_layer_position(index, image_layer.position)
	
#----------------------------------------------------------------------------------------------------
func init_viewport():
	RenderingServer.viewport_set_update_mode(viewport_id, RenderingServer.VIEWPORT_UPDATE_WHEN_VISIBLE)  # 设置更新模式
	RenderingServer.viewport_set_clear_mode(viewport_id, RenderingServer.VIEWPORT_CLEAR_ALWAYS)
	RenderingServer.viewport_set_active(viewport_id, true)  # 激活
	RenderingServer.viewport_set_transparent_background(viewport_id, true)
	
	RenderingServer.viewport_attach_canvas(viewport_id, viewport_canvas_id)  # 添加 canvas_layer
	RenderingServer.canvas_item_set_parent(canvas_id, viewport_canvas_id)
	set_viewport_size(canvas_size)
	
func set_viewport_size(size:Vector2):
	if _prev_size != size:
		_prev_size = size
		RenderingServer.viewport_set_size(viewport_id, size.x, size.y) # 设置尺寸

func get_texture_rid() -> RID:
	return RenderingServer.viewport_get_texture(viewport_id)
	
#----------------------------------------------------------------------------------------------------
func create_layer(index:int, image:Image):
	if index < 0 or rids.size() < index :
		return false
	var rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(rid, canvas_id)
	rids.insert(index, rid)
	textures.insert(index, ImageTexture.create_from_image(image) if image and not image.is_empty() else ImageTexture.new())

func delete_layer(index:int):
	textures.remove_at(index)
	RenderingServer.free_rid(rids[index])
	rids.remove_at(index)
	queue_redraw()
	
func clear():
	textures.clear()
	for rid in rids:
		RenderingServer.free_rid(rid)
	rids = []
	queue_redraw()

func update_layer_texture(index:int, value:Image):
	var texture = textures[index]
	if texture.get_size() != Vector2(value.get_size()):
		texture.set_image(value)
	else:
		texture.update(value)
	queue_redraw_layer(index)

func set_layer_position(index:int, value:Vector2):
	RenderingServer.canvas_item_set_transform(rids[index], Transform2D().translated(value))

func set_layer_visible(index:int, value:bool):
	RenderingServer.canvas_item_set_visible(rids[index], value)

func queue_redraw_layer(index:int):
	if index == -1:
		_redraw_dirty = range(textures.size())
	else:
		_redraw_dirty.append(index)

func draw_layer(index:int):
	var rid = rids[index]
	var texture :ImageTexture= textures[index]
	RenderingServer.canvas_item_clear(rid)
	if _debug_mode:
		RenderingServer.canvas_item_add_rect(rid, Rect2(Vector2.ZERO, texture.get_size()), Color.RED)
	texture.draw(rid, Vector2.ZERO)

func _draw() -> void:
	RenderingServer.canvas_item_add_texture_rect(get_canvas_item(), Rect2(0,0,canvas_size.x, canvas_size.y), get_texture_rid())
