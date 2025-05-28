class_name ShapeTool extends BaseTool

enum ShapeType {NONE, LINE, RECTANGLE, RECTANGLE_FILL, ELLIPSE, ELLIPSE_FILL, BEZEIR} # POLYLINE ?

var shape_type := ShapeType.LINE

var ellipse := Ellipse.new() # ComputeShaderObject
var outline := Outline.new() # ComputeShaderObject

var _shape_indicator : ShapeIndicator

var cell_pos_floor : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_floor
var cell_pos_round : Vector2i:
	get(): return _tool_system.cursor_tool.cell_pos_round
var shape_data :ShapeData= RectShapeData.new()

var _draw_started := false

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
	shape_data.clear()
	raise_shape_data_updated()
	
func activate() -> void:
	shape_data.clear()
	if not _shape_indicator:
		_shape_indicator = ShapeIndicator.new()
	add_indicator(_shape_indicator)
		
# 工具禁用时调用
func deactivate() -> void:
	shape_data.clear()
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

func _handle_value_changed(prop_name:String, value:Variant):
	match prop_name:
		"shape_type":
			if value == ShapeType.BEZEIR:
				shape_data = BezierShapeData.new()
			else:
				shape_data = RectShapeData.new()

func _on_action_called(action:String, state:ActionHandler.State):
	if state == ActionHandler.State.JUST_PRESSED:
		_check_draw_started()
	if not is_draw_started():
		return 
	match action:
		ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match shape_type:
				ShapeType.LINE:
					_handle_line(state)
				ShapeType.RECTANGLE, ShapeType.RECTANGLE_FILL:
					_handle_rect(state)
				ShapeType.ELLIPSE, ShapeType.ELLIPSE_FILL:
					_handle_ellipse(state)
				ShapeType.BEZEIR:
					_handle_bezier(state)
		ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			shape_data.clear()
			raise_shape_data_updated()

func _check_draw_started():
	if not project_controller.is_layer_editable(project_controller.get_active_layer_index()):
		_draw_started = false
		PopupArrowPanelManager.get_from_ui_system().quick_notify_dialog("编辑失败:当前图层已锁定！")
	else:
		_draw_started = true

func is_draw_started():
	return _draw_started

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
					_handle_line(ActionHandler.State.PRESSED)
				ShapeType.RECTANGLE, ShapeType.RECTANGLE_FILL:
					_handle_rect(ActionHandler.State.PRESSED)
				ShapeType.ELLIPSE, ShapeType.ELLIPSE_FILL:
					_handle_ellipse(ActionHandler.State.PRESSED)
				ShapeType.BEZEIR:
					_handle_bezier(ActionHandler.State.PRESSED)

func _handle_two_point_rect(state:ActionHandler.State):
	# NOTE: 通用的两点模型
	match state:
		ActionHandler.State.JUST_PRESSED:
			if not shape_data.mask:
				shape_data.mask = true
				shape_data.p1 = cell_pos_floor
				shape_data.p2 = cell_pos_floor
			else:
				_shape_apply()
				shape_data.clear()
			raise_shape_data_updated()
			
		ActionHandler.State.PRESSED:
			if not shape_data.is_dynamic_state():
				return 
			shape_data.p2 = cell_pos_floor
			raise_shape_data_updated()
			
## LineShape
func _handle_line(state:ActionHandler.State):
	_handle_two_point_rect(state)

## rect
func _handle_rect(state:ActionHandler.State):
	_handle_two_point_rect(state)
			
## ellipse
func _handle_ellipse(state:ActionHandler.State):
	_handle_two_point_rect(state)

## Bezier
func _handle_bezier(state:ActionHandler.State):
	match state:
		ActionHandler.State.JUST_PRESSED:
			match shape_data.state:
				0:
					shape_data.p1 = cell_pos_floor
					shape_data.h1 = Vector2i.ZERO
					shape_data.p2 = cell_pos_floor
					shape_data.h2 = Vector2i.ZERO
					shape_data.state += 1
				1: 
					shape_data.p2 = cell_pos_floor
					shape_data.h2 = Vector2i.ZERO
					shape_data.state += 1
				2: 
					shape_data.h1 = cell_pos_floor - shape_data.p1
					shape_data.state += 1
				3:
					_shape_apply()
					shape_data.clear()
			raise_shape_data_updated()
			
		ActionHandler.State.PRESSED:
			if not shape_data.is_dynamic_state():
				return 
			match shape_data.state:
				1:
					shape_data.p2 = cell_pos_floor
					shape_data.h2 = Vector2i.ZERO
				2:
					shape_data.h1 = cell_pos_floor - shape_data.p1
				3:
					shape_data.h2 = cell_pos_floor - shape_data.p2
			raise_shape_data_updated()

## 
func _shape_apply():
	var shape_image_data = get_shape_image_data()
	if not shape_data:
		return 
	var rect = shape_image_data.rect
	var output_mask = shape_image_data.image
	
	var image_layers := project_controller.get_image_layers()
			
	var active_color = SystemManager.color_system.active_color
	var active_index = project_controller.get_active_layer_index()
	
	var fill_image = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	fill_image.fill(active_color) # NOTE: 只有这样透明像素才能用
	
	var undo_image_layer = image_layers.get_layer(active_index).duplicate(true)
	project_controller.action_blit_image(active_index, fill_image, output_mask, Rect2(Vector2.ZERO, rect.size), rect.position, 
										undo_image_layer, ImageLayers.BlitMode.BLEND
										)

func get_shape_image_data() -> Dictionary:
	if shape_type == ShapeType.BEZEIR:
		return get_bezier_shape_image_data_with(shape_data)
	else:
		return get_rect_shape_image_data_with(shape_data, shape_type)
	
func get_rect_shape_image_data_with(shape_data:RectShapeData, shape_type:ShapeType) -> Dictionary:
	var canvas_size = main_canvas_data.real_canvas_size
	var rect = RectUtils.create_rect_from_points([shape_data.p1, shape_data.p2])
	rect.size += Vector2.ONE
	rect = Rect2i(Vector2.ZERO, canvas_size).intersection(rect)
	if not rect:
		return {}
	match shape_type:
		ShapeType.LINE:
			var image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
			var points = Geometry2D.bresenham_line(shape_data.p1, shape_data.p2)
			for p in points:
				if p.x < 0 or p.y < 0 or canvas_size.x <= p.x or canvas_size.y <= p.y:
					continue
				var fp = p-rect.position
				image.set_pixelv(fp, Color.WHITE)
			return {"image":image, "rect":rect}
			
		ShapeType.RECTANGLE, ShapeType.RECTANGLE_FILL:
			var image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			if shape_type == ShapeType.RECTANGLE:
				image = outline.compute(Outline.OutlineData.create(image, Color.WHITE))
			return {"image":image, "rect":rect}
		
		ShapeType.ELLIPSE, ShapeType.ELLIPSE_FILL:
			var ellipse_data = Ellipse.EllipseData.create(Vector2(rect.size.x, rect.size.y), Color.WHITE)
			var image = ellipse.compute(ellipse_data)
			if shape_type == ShapeType.ELLIPSE:
				image = outline.compute(Outline.OutlineData.create(image, Color.WHITE))
			return {"image":image, "rect":rect}
	return {}

func get_bezier_shape_image_data_with(shape_data:BezierShapeData):
	var canvas_size = main_canvas_data.real_canvas_size
	var rect = RectUtils.create_rect_from_points([shape_data.p1, shape_data.p2, shape_data.p1+shape_data.h1, shape_data.p2+shape_data.h2])
	rect.size += Vector2.ONE
	rect = Rect2i(Vector2.ZERO, canvas_size).intersection(rect)
	if not rect:
		return {}
	var image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var curve = shape_data.get_curve()
	var bpoints = curve.get_baked_points()
	var points := PackedVector2Array()
	var pcount = bpoints.size()
	for i in pcount:
		if i == pcount-1:
			break
		var p1 = bpoints[i]
		var p2 = bpoints[i+1]
		points.append_array(Geometry2D.bresenham_line(p1, p2))
	
	for p in points:
		if p.x < 0 or p.y < 0 or canvas_size.x <= p.x or canvas_size.y <= p.y:
			continue
		var fp = Vector2i(p)-rect.position
		image.set_pixelv(fp, Color.WHITE)
	return {"image":image, "rect":rect}
	
func raise_shape_data_updated():
	property_updated.emit("shape_data", shape_data)

class ShapeData:
	func is_dynamic_state() -> bool:
		return false
	func clear():
		pass
		
class RectShapeData extends ShapeData:
	var p1:Vector2i
	var p2:Vector2i
	var mask := false

	func is_dynamic_state() -> bool:
		return mask 
	
	func clear():
		p1 = Vector2i.ZERO
		p2 = Vector2i.ZERO
		mask = false
		
class BezierShapeData extends ShapeData:
	var p1:Vector2i
	var p2:Vector2i
	var h1:Vector2i
	var h2:Vector2i
	var state := 0
	var _curve = Curve2D.new()
	
	func _init() -> void:
		_curve.add_point(Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO)
		_curve.add_point(Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO)
	
	func get_curve() -> Curve2D:
		const _half = Vector2.ONE*0.5 # NOTE: 偏移到像素中心效果会更好一些
		_curve.set_point_position(0, Vector2(p1)+_half)
		_curve.set_point_out(0, Vector2(h1)+_half)
		_curve.set_point_position(1, Vector2(p2)+_half)
		_curve.set_point_in(1, Vector2(h2)+_half)
		return _curve
	
	func is_dynamic_state() -> bool:
		return state != 0 
	
	func clear():
		p1 = Vector2i.ZERO
		p2 = Vector2i.ZERO
		h1 = Vector2i.ZERO
		h2 = Vector2i.ZERO
		state = 0
