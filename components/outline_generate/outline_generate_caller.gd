extends Node

@export var widget: Button

func _ready() -> void:
	if not widget:
		widget = get_parent()
	
	widget.pressed.connect(func():
		
			
		var project_controller = SystemManager.project_system.project_controller
		var index = project_controller.get_active_layer_index()
		var image_layers = project_controller.get_image_layers()
		var res_data = project_controller.get_active_layer_masked_image_data()
		if not res_data:
			PopupArrowPanelManager.get_from_ui_system().quick_notify_dialog("创建描边失败：请确保图片存在有效像素!", 2)
			return 
		var outline_generate = PopupArrowPanelManager.get_from_ui_system().call_popup_panel_plugin("outline_generate")
		if not outline_generate:
			return 
		var input_image = res_data.get("image")
		var used_rect = res_data.get("rect", Rect2i())
		outline_generate.init_with(input_image, SystemManager.color_system.get_active_color())
		outline_generate.confirmed.connect(func():
			var outline_image = outline_generate.get_result_image()
			if outline_image:
				var undoimage_layer = image_layers.get_layer(index).duplicate(true)
				var dst = used_rect.position - Vector2i.ONE*outline_generate.expand_size
				project_controller.action_blit_image(index, outline_image, outline_image, 
							Rect2(Vector2.ZERO, outline_image.get_size()), dst, 
							undoimage_layer
				)
							
			outline_generate.queue_free()
		)
		outline_generate.canceled.connect(func():
			outline_generate.queue_free()
		)
	)
