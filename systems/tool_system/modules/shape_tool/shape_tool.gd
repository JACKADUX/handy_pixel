class_name ShapeTool extends BaseTool

enum ShapeType {NONE, LINE, RECTANGLE, RECTANGLE_FILL, ELLIPSE, ELLIPSE_FILL, BEZEIR} # POLYLINE ?

var shape_type := ShapeType.LINE

var ellipse := Ellipse.new()
var outline := Outline.new()

var _shape_indicator : ShapeIndicator

static func get_tool_name() -> String:
	return "shape"

func register_action(action_handler:ActionHandler):
	#action_handler.register_action(ACTION_SELECT_ALL)
	pass

func register_shader(compute_shader_system:ComputeShaderSystem):
	compute_shader_system.register_compute_shader_object("ellipse", ellipse)
	compute_shader_system.register_compute_shader_object("outline", outline)

func initialize() -> void:
	ellipse.free_rids()
	outline.free_rids()
	if _shape_indicator:
		_shape_indicator.update()

func activate() -> void:
	if not _shape_indicator:
		_shape_indicator = ShapeIndicator.new()
	add_indicator(_shape_indicator)
		
# 工具禁用时调用
func deactivate() -> void:
	remove_indicator(_shape_indicator)
	

func get_tool_data() -> Dictionary:
	return {
		"shape_type":shape_type
	}

func _get_action_button_datas() -> Array:
	return [
		ActionButtonPanel.create_action_button_data(0, ToolSystem.ACTION_TOOL_MAIN_PRESSED, ToolSystem.main_pressed_icon),
		ActionButtonPanel.create_action_button_data(1, ToolSystem.ACTION_TOOL_CANCEL_PRESSED, ToolSystem.cancel_pressed_icon),
	]

func _on_action_called(action:String, state:ActionHandler.State):
		match action:
			ToolSystem.ACTION_TOOL_MAIN_PRESSED:
				match shape_type:
					ShapeType.LINE:
						_line(state)

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_STATE_CHANGED:
			if data.state == InputRecognizer.State.NONE:
				show_action_button_panel(false)
			elif data.state == InputRecognizer.State.HOVER:
				show_action_button_panel(true)
		InputRecognizer.EVENT_HOVERED:
			match shape_type:
				ShapeType.LINE:
					_line(ActionHandler.State.PRESSED)

func create_ellipse_image(width:int, height:int, color:=Color.WHITE, only_outline:=false) -> Image:
	var ellipse_data = Ellipse.EllipseData.create(Vector2(width, height), color)
	var img = ellipse.compute(ellipse_data)
	if img and only_outline :
		var outline_data = Outline.OutlineData.create(img, color)
		img = outline.compute(outline_data)
	return img


var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round
var main_canvas_data :CanvasData = preload("res://systems/canvas_system/main_canvas_data.tres")

## LineShape
class LineShapeData:
	var p1:Vector2i
	var mask1 := false
	var p2:Vector2i

	func is_dynamic_state() -> bool:
		return mask1 
		
var shape_data := LineShapeData.new()

func _line(state):
	match state:
		ActionHandler.State.JUST_PRESSED:
			if not shape_data.mask1:
				shape_data.mask1 = true
				shape_data.p1 = cell_pos_floor
				shape_data.p2 = cell_pos_floor
			else:
				_shape_apply()
				shape_data.mask1 = false
			raise_shape_data_updated()
			
		ActionHandler.State.PRESSED:
			if not shape_data.is_dynamic_state():
				return 
			shape_data.p2 = cell_pos_floor
			raise_shape_data_updated()
			
		ActionHandler.State.JUST_RELEASED:
			pass
			
func _shape_apply():
	var shape_image_data = get_shape_image_data()
	if not shape_data:
		return 
	var rect = shape_image_data.rect
	var output_mask = shape_image_data.image
	
	var image_layers := project_controller.get_image_layers()
	
	var select_tool :SelectionTool = _tool_system.get_tool("selection_tool")
	var selection_mask_image:Image
	if select_tool.selection_mask_image and not select_tool.selection_mask_image.is_invisible():
		selection_mask_image = select_tool.selection_mask_image
		
	var active_color = SystemManager.color_system.active_color
	var active_index = project_controller.get_active_layer_index()
	var image = image_layers.create_canvas_image(active_index)
	
	
	var fill_image = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	fill_image.fill(active_color) # NOTE: 只有这样透明像素才能用
	
	if selection_mask_image:
		selection_mask_image = selection_mask_image.get_region(rect)
		var inter_mask = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
		inter_mask.blit_rect_mask(output_mask, selection_mask_image, Rect2(Vector2.ZERO, rect.size), Vector2i.ZERO)
		output_mask = inter_mask
	
	var undo_image_layer = image_layers.get_layer(active_index).duplicate(true)
	project_controller.action_blit_image(active_index, fill_image, output_mask, Rect2(Vector2.ZERO, rect.size), rect.position, 
										undo_image_layer, ImageLayers.BlitMode.BLIT
										)

func get_shape_image_data() -> Dictionary:
	match shape_type:
		ShapeType.LINE:
			var canvas_size = main_canvas_data.real_canvas_size
			var rect = RectUtils.create_rect_from_points([shape_data.p1, shape_data.p2])
			rect.size += Vector2.ONE
			rect = Rect2i(Vector2.ZERO, canvas_size).intersection(rect)
			if not rect:
				return {}
			var image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
			var points = Geometry2D.bresenham_line(shape_data.p1, shape_data.p2)
			for p in points:
				var fp = p-rect.position
				if p.x < 0 or p.y < 0 or canvas_size.x <= p.x or canvas_size.y <= p.y:
					continue
				image.set_pixelv(fp, Color.WHITE)
			return {"image":image, "rect":rect}
	return {}

func raise_shape_data_updated():
	# NOTE:等两帧再清除，可以避免闪烁
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	property_updated.emit("shape_data", shape_data)
