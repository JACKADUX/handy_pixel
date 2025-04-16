extends Control

@onready var action_button_panel :ActionButtonPanel = SystemManager.ui_system.action_button_panel
@onready var main_panel: MarginContainer = %MainPanel
@onready var hover_panel: Control = %HoverPanel

@onready var project_manage_panel: ProjectManagePanel = %ProjectManagePanel
@onready var new_project_panel: PanelContainer = %NewProjectPanel

@onready var home_button: Button = %HomeButton

func _ready() -> void:
	
	SystemManager.tool_system.action_button_requested.connect(func(action_button_datas:Array, value:bool):
		if value:
			var input_data = SystemManager.input_system.input_recognizer.input_datas.get_input_data(0)
			var pos = input_data.start_position
			main_panel.hide()
			hover_panel.show()
			var area_type = LayoutHelper.get_point_type_lr(pos, get_viewport_rect())
			if area_type == LayoutHelper.AreaTypeLR.LEFT:
				action_button_panel.set_mode(2)
			elif area_type == LayoutHelper.AreaTypeLR.RIGHT:
				action_button_panel.set_mode(1)
			action_button_panel.setup_action_buttons(action_button_datas)
			action_button_panel.show()
		else:
			main_panel.show()
			hover_panel.hide()
			action_button_panel.hide()
	)
	
	project_manage_panel.new_project_requested.connect(func():
		new_project_panel.show()
	)
	project_manage_panel.return_canvas_requested.connect(func():
		project_manage_panel.hide()
	)
	
	new_project_panel.ok_pressed.connect(func():
		project_manage_panel.hide()
		new_project_panel.hide()
		var id = SystemManager.project_system.new_project(Time.get_datetime_string_from_system(),
				SystemManager.project_system.preset_canvas_size,
				SystemManager.project_system.preset_canvas_bg_color
		)
		SystemManager.project_system.set_active_project(id)
	)
	new_project_panel.cancel_pressed.connect(func():
		new_project_panel.hide()
	)
	
	home_button.pressed.connect(func():
		SystemManager.db_system.save_data()
		project_manage_panel.show()
		project_manage_panel.update()
	)
	
	
