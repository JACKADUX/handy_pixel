class_name TempActionButtons extends MarginContainer

@onready var copy_select_button: Button = %CopySelectButton
@onready var past_select_button: Button = %PastSelectButton
@onready var delete_select_button: Button = %DeleteSelectButton
@onready var cancel_select_button: Button = %CancelSelectButton

var project_controller : ProjectController

func _ready() -> void:
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	
	project_controller = SystemManager.project_system.project_controller 
	
	project_controller.action_called.connect(func(action_name:String, data:Dictionary):
		match action_name:
			project_controller.ACTION_IMAGE_MASK_CHANGED:
				if project_controller.get_image_mask().has_mask():
					copy_select_button.show()
					delete_select_button.show()
					cancel_select_button.show()
				else:
					copy_select_button.hide()
					delete_select_button.hide()
					cancel_select_button.hide()
				update()
					
			project_controller.ACTION_IMAGE_MASK_COPY:
				if project_controller._copy_data:
					past_select_button.show()
				else:
					past_select_button.hide()
				update()
	)

	copy_select_button.hide()
	past_select_button.hide()
	delete_select_button.hide()
	cancel_select_button.hide()
	update()
	
func update():
	var any_vis = false
	for i in get_child(0).get_children():
		if i.visible:
			any_vis = true
			break
	visible = any_vis
	#set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
