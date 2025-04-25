class_name FillColorTool extends BaseTool

const ACTION_FILL_COLOR := "action_fill_color"

# FIXME : 目前的选区填充逻辑不正确，需要将选取蒙版传给glsl做边界判定，
#		  不过由于影响不是很大可以暂时先忽略。

var tolerance :float = 0.01  # 填充容差 0-> 当前颜色， 1->所有颜色

var flood_fll := FloodFill.new()

var rd := RenderingServer.create_local_rendering_device()

func _init() -> void:
	flood_fll.set_rd(rd)

func initialize() -> void:
	flood_fll.free_rids()

static func get_tool_name() -> String:
	return "fill_color"

func get_tool_data() -> Dictionary:
	return {
		"tolerance": tolerance
	}
	
func action_fill_active_color_on_active_layer(qury_pos:Vector2i):
	var image_layers := project_controller.get_image_layers()
	var rect = Rect2i(Vector2.ZERO, image_layers.canvas_size)
	if not rect.has_point(qury_pos):
		return 
	
	var select_tool :SelectionTool = _tool_system.get_tool("selection_tool")
	var selection_mask_image:Image
	if select_tool.selection_mask_image and not select_tool.selection_mask_image.is_invisible():
		selection_mask_image = select_tool.selection_mask_image
		if selection_mask_image.get_pixelv(qury_pos).a == 0:
			# 真正选区的范围外面， 选区的形状可以不是矩形 所以需要判定像素
			return 
	var active_color = SystemManager.color_system.active_color
	var active_index = project_controller.get_active_layer_index()
	var image = image_layers.create_canvas_image(active_index)
	var output_mask = flood_fll.compute(image, qury_pos, Color.WHITE, tolerance)
	var inter_mask = Image.create_empty(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	inter_mask.fill(active_color) # NOTE: 只有这样透明像素才能用
	if selection_mask_image:
		inter_mask.blit_rect_mask(inter_mask, selection_mask_image, rect, Vector2i.ZERO)
		output_mask = inter_mask
	var undo_image_layer = image_layers.get_layer(active_index).duplicate(true)
	project_controller.action_blit_image(active_index, inter_mask, output_mask, rect, Vector2i.ZERO, 
										undo_image_layer, ImageLayers.BlitMode.BLIT
										)
