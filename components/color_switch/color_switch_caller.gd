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
			PopupArrowPanelManager.get_from_ui_system().quick_notify_dialog("颜色替换失败：请确保图片存在有效像素!", 2)
			return 
		var color_switch = PopupArrowPanelManager.get_from_ui_system().call_popup_panel_plugin("color_switch")
		if not color_switch:
			return 
		var input_image = res_data.get("image")
		var used_rect = res_data.get("rect", Rect2i())
		color_switch.init_with(input_image, SystemManager.color_system.get_active_color())
		color_switch.confirmed.connect(func():
			var color_switch_image = color_switch.get_result_image()
			if color_switch_image:
				var undoimage_layer = image_layers.get_layer(index).duplicate(true)
				var dst = used_rect.position
				project_controller.action_blit_image(index, color_switch_image, color_switch_image, 
							Rect2(Vector2.ZERO, color_switch_image.get_size()), dst, 
							undoimage_layer
				)
							
			color_switch.queue_free()
		)
		color_switch.canceled.connect(func():
			color_switch.queue_free()
		)
	)
