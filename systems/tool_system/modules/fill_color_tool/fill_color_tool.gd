class_name FillColorTool extends BaseTool

const ACTION_FILL_COLOR := "action_fill_color"

# FIXME : 目前的选区填充逻辑不正确，需要将选取蒙版传给glsl做边界判定，
#		  不过由于影响不是很大可以暂时先忽略。

var tolerance :float = 0.01  # 填充容差 0-> 当前颜色， 1->所有颜色

var flood_fill := CSO_FloodFill.new()

static func get_tool_name() -> String:
	return "fill_color"
	
func register_action(action_handler:ActionHandler):
	action_handler.register_action(ACTION_FILL_COLOR)

func register_shader(compute_shader_system:ComputeShaderSystem):
	compute_shader_system.register_compute_shader_object("flood_fill", flood_fill)

func initialize() -> void:
	flood_fill.free_rids()

func get_tool_data() -> Dictionary:
	return {
		"tolerance": tolerance
	}
	
func action_fill_active_color_on_active_layer(qury_pos:Vector2i):
	var image_layers := project_controller.get_image_layers()
	var active_color = SystemManager.color_system.active_color
	var active_index = project_controller.get_active_layer_index()
	var image = image_layers.create_canvas_image(active_index)
	if image.get_pixelv(qury_pos) == active_color:
		return
	var rect = Rect2i(Vector2.ZERO, image_layers.canvas_size)
	if not rect.has_point(qury_pos):
		return 
	var mask_image:Image = project_controller.get_image_mask().get_mask()
	if mask_image and mask_image.get_pixelv(qury_pos).a == 0:
		# NOTE : 真正选区的范围外面， 选区的形状可以不是矩形 所以需要判定像素
		return 
	var flood_fill_data = CSO_FloodFill.FloodFillData.create(
			image, mask_image, qury_pos, Color.WHITE, tolerance
	)
	var output_mask = flood_fill.compute(flood_fill_data)
	if not output_mask:
		return 
	var fill_image = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	fill_image.fill(active_color) # NOTE: 只有这样透明像素才能用
	var undo_image_layer = image_layers.get_layer(active_index).duplicate(true)
	project_controller.action_blit_image(active_index, fill_image, output_mask, rect, Vector2i.ZERO, 
										undo_image_layer, ImageLayers.BlitMode.BLIT
										)
