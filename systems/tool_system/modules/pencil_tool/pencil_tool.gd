class_name PencilTool extends BaseTool

const ACTION_DRAW_COLOR := "action_draw_color"

# 画笔属性
enum PenShape { CIRCLE, SQUARE }

var pen_shape := PenShape.CIRCLE 
var pen_size :int = 1


var _pen_shape_cursor :PenShapeCursor

var _pen_color :Color
var _color_image : Image
var _color_image_dirty := true
var _mask_image : Image
var _mask_image_dirty := true

var _blit_color_image : Image
var _blit_mask_image : Image
var _prev_image_layer : ImageLayer

var _cache_pen_position := Vector2i(INF,INF)
var _draw_started := false
var _draw_mode : ImageLayers.BlitMode


const pencil_icon = preload("res://assets/icons/stylus_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const erase_icon = preload("res://assets/icons/ink_eraser_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const pick_color_icon = preload("res://assets/icons/colorize_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")
const fill_color_icon = preload("res://assets/icons/colors_96dp_FFFFFF_FILL1_wght400_GRAD0_opsz48.svg")


const PENCIL_TOOL_UI = preload("res://systems/tool_system/modules/pencil_tool/pencil_tool_ui.tscn")

var tool_ui :Control

## OVERRIDE ---------------------------------------------------------------------------------------- 
static func get_tool_name() -> String:
	return "pencil"

func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_DRAW_COLOR)

## 工具激活时调用
func activate() -> void:
	_pen_shape_cursor = PenShapeCursor.new()
	add_indicator(_pen_shape_cursor)
	_pen_color = get_active_color()
	set_mask_image_dirty()
	
	var tool_ui_control := _tool_system.get_tool_ui_control()
	if tool_ui_control:
		tool_ui = PENCIL_TOOL_UI.instantiate()
		tool_ui_control.add_tool_ui(tool_ui)
		tool_ui.hide()

	
## 工具禁用时调用
func deactivate() -> void:
	remove_indicator(_pen_shape_cursor)
	tool_ui.queue_free()
	tool_ui = null

func get_tool_data() -> Dictionary:
	return {
		"pen_shape": pen_shape,
		"pen_size": pen_size
	}

func _get_action_button_datas():
	var actions = [
		ActionButtonPanel.create_action_button_data(0, PencilTool.ACTION_DRAW_COLOR, pencil_icon),
		ActionButtonPanel.create_action_button_data(2, ColorPickerTool.ACTION_PICK_COLOR, pick_color_icon),
		ActionButtonPanel.create_action_button_data(3, FillColorTool.ACTION_FILL_COLOR, fill_color_icon),
		ActionButtonPanel.create_action_button_data(4, EraserTool.ACTION_ERASE_COLOR, erase_icon),
	]
	return actions
		

func _handle_value_changed(prop_name:String, value:Variant):
	if prop_name == "pen_shape" or prop_name == "pen_size":
		set_mask_image_dirty()	

func _on_action_called(action:String, state:ActionHandler.State):
	match action:
		ColorPickerTool.ACTION_PICK_COLOR:
			match state:
				ActionHandler.State.PRESSED:	
					var color_picker = _tool_system.get_tool(ColorPickerTool.get_tool_name())
					var color = color_picker.pick_color(_tool_system.cursor_tool.cell_pos_floor)
					SystemManager.ui_system.model_data_mapper.set_value("active_color", color)
		_:
			_draw_relavent_action_called(action, state)
			
func _draw_relavent_action_called(action:String, state:ActionHandler.State):
	if state == ActionHandler.State.JUST_PRESSED:
		_cache_pen_position = Vector2i(INF,INF)
		_check_draw_started()
	if not is_draw_started():
		return 
	match action:
		PencilTool.ACTION_DRAW_COLOR, ToolSystem.ACTION_TOOL_MAIN_PRESSED:
			match state:
				ActionHandler.State.JUST_PRESSED:
					var active_color = get_active_color()
					set_pen_color(active_color)
					if active_color.a > 0:
						set_draw_mode(ImageLayers.BlitMode.BLEND)
					else:
						set_draw_mode(ImageLayers.BlitMode.BLIT)
					begin_draw()
				ActionHandler.State.PRESSED:
					_auto_fluent_draw()
				ActionHandler.State.JUST_RELEASED:
					end_draw()
		EraserTool.ACTION_ERASE_COLOR, ToolSystem.ACTION_TOOL_CANCEL_PRESSED:
			match state:
				ActionHandler.State.JUST_PRESSED:
					set_pen_color(Color.TRANSPARENT)
					set_draw_mode(ImageLayers.BlitMode.BLIT)
					begin_draw()
				ActionHandler.State.PRESSED:
					_auto_fluent_draw()
				ActionHandler.State.JUST_RELEASED:
					end_draw()
		FillColorTool.ACTION_FILL_COLOR:
			match state:
				ActionHandler.State.JUST_RELEASED:
					var fill_color = _tool_system.get_tool(FillColorTool.get_tool_name()) as FillColorTool
					fill_color.action_fill_active_color_on_active_layer(_tool_system.cursor_tool.cell_pos_floor)

func _on_event_occurred(event:String, data:Dictionary):
	match event:
		InputRecognizer.EVENT_STATE_CHANGED:
			if data.state == InputRecognizer.State.NONE:
				show_action_button_panel(false)
				show_tool_ui(false)
				
			elif data.state == InputRecognizer.State.HOVER:
				show_action_button_panel(true)
				show_tool_ui(true)

func _check_draw_started():
	if not project_controller.is_layer_editable(project_controller.get_active_layer_index()):
		_draw_started = false
		PopupArrowPanelManager.get_from_ui_system().quick_notify_dialog("编辑失败:当前图层已锁定！")
	else:
		_draw_started = true

func is_draw_started():
	return _draw_started

func show_tool_ui(value:bool):
	if value:
		var area_type = get_layout_area_type()
		if area_type == LayoutHelper.AreaTypeLR.LEFT:
			tool_ui.set_on_right()
		elif area_type == LayoutHelper.AreaTypeLR.RIGHT:
			tool_ui.set_on_left()
		tool_ui.show()
	else:
		tool_ui.hide()
	
func get_active_color():
	return SystemManager.color_system.active_color

## Action -------------------------------------------------------------------------------------------- 
func begin_draw():
	var active_layer_index = project_controller.get_active_layer_index()
	var image_layers := project_controller.get_image_layers()
	_blit_color_image = image_layers.new_empty_image()
	_blit_mask_image = image_layers.new_empty_image()
	_prev_image_layer = image_layers.get_layer(active_layer_index).duplicate(true)

func draw_list(src_image:Image, mask_image:Image, dst_list:PackedVector2Array):
	if not dst_list:
		return 
	#var select_tool :SelectionTool = _tool_system.get_tool("selection_tool")
	var inter_mask :Image= mask_image
	var rect = Rect2(Vector2.ZERO, mask_image.get_size())
	
	for pen_pos in dst_list:
		_blit_color_image.blit_rect_mask(src_image, inter_mask, rect, pen_pos)
		_blit_mask_image.blit_rect_mask(mask_image, inter_mask, rect, pen_pos)
	var used_rect = _blit_mask_image.get_used_rect()
	# NOTE: set_layer 是为了半透明效果，必须要这么做
	project_controller.set_layer(project_controller.get_active_layer_index(), _prev_image_layer.duplicate(true))
	project_controller.blit_image(project_controller.get_active_layer_index(), 
								_blit_color_image, 
								_blit_mask_image, 
								used_rect, 
								used_rect.position, 
								_draw_mode
	)
	
func end_draw():
	var used_rect = _blit_mask_image.get_used_rect()
	# NOTE: set_layer 是为了半透明效果，必须要这么做
	# WARNING: 这部分方法涉及到的参数非常敏感，除非出现bug或者需要新增功能否则不要轻易改动。
	project_controller.set_layer(project_controller.get_active_layer_index(), _prev_image_layer.duplicate(true))
	project_controller.action_blit_image(project_controller.get_active_layer_index(),
										_blit_color_image.get_region(used_rect),
										_blit_mask_image.get_region(used_rect),
										Rect2(Vector2.ZERO, used_rect.size),
										used_rect.position,
										_prev_image_layer,
										_draw_mode
	)

## Utils -------------------------------------------------------------------------------------------- 
func _auto_fluent_draw():
	# NOTE: 在大尺度上绘制时 _generate_pen_pos_list 生成的数量可能会过多并且大部分区域是重叠的
	#		可以根据画笔的半径来自动把中间重叠的步骤跳过
	# NOTE: 此方法在会带来很大的性能提升
	var pos_list = _generate_pen_pos_list()
	if not pos_list:
		return 
	var mask_image = get_mask_image()
	var size = mask_image.get_size()*0.5
	var count = pos_list.size()
	var step = ceil((size.x+size.y)*0.5)
	pos_list = pos_list.slice(0, count, step)
	draw_list(get_color_image(), mask_image, pos_list)

func _generate_pen_pos_list() -> Array[Vector2i]:
	# NOTE: 可以保证线条是连续的
	var pen_pos := get_pen_position()
	var prev_pos = _cache_pen_position if _cache_pen_position != Vector2i(INF,INF) else pen_pos
	if _cache_pen_position == pen_pos:
		return []
	_cache_pen_position = pen_pos
	var pos_list := Geometry2D.bresenham_line(prev_pos, pen_pos)
	if pos_list.size() > 2:
		# 把与上一步重复的部分去除
		pos_list.pop_front()
	return pos_list
	
func set_mask_image_dirty():
	_mask_image_dirty = true
	_color_image_dirty = true
	
func set_pen_color(color:Color):
	_pen_color = color
	if _color_image_dirty:
		get_color_image()
	_color_image.fill(_pen_color)

func set_draw_mode(mode:ImageLayers.BlitMode):
	_draw_mode = mode

func get_mask_image() -> Image:
	if _mask_image_dirty:
		_mask_image_dirty = false
		_mask_image = generate_alpha_image(pen_size, pen_shape)
	return _mask_image

func get_color_image() -> Image:
	if _color_image_dirty:
		_color_image_dirty = false
		_color_image = get_mask_image().duplicate()
		_color_image.fill(_pen_color)
	return _color_image

func get_pen_position() -> Vector2i:
	return _get_draw_cell_pos(_tool_system.cursor_tool.cell_pos_round, _tool_system.cursor_tool.cell_pos_floor)

func _is_even_pen_size() -> bool:
	return pen_size % 2 == 0

func _get_draw_cell_pos(cell_pos_round:Vector2i, cell_pos_floor:Vector2i) -> Vector2i:
	# NOTE: 根据像素的奇偶做一个偏移， 输入的参数是中心位置，返回的是左上角的位置
	var cell_pos = cell_pos_round if _is_even_pen_size() else cell_pos_floor
	var ofs = Vector2.ONE*pen_size*0.5
	return cell_pos-Vector2i(ofs)

# 生成笔刷形状的坐标偏移
func generate_alpha_image(size: int, shape: PenShape) -> Image:
	match shape:
		PenShape.SQUARE:
			var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE)
			return image
		PenShape.CIRCLE:
			# NOTE
			var ellipse = Ellipse.get_from_system("ellipse") as Ellipse
			if not ellipse:
				return 
			return ellipse.compute(Ellipse.EllipseData.create(Vector2.ONE*size, Color.WHITE))
	return 
