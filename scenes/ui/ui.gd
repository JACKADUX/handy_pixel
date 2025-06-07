extends Control

@onready var main_panel: MarginContainer = %MainPanel
@onready var layers: Control = %Layers  # 用来新增页面 比如 ProjectManagePanel
@onready var tool_ui_control: ToolUIControl = %ToolUIControl
@onready var popup_arrow_panel_manager: PopupArrowPanelManager = %PopupArrowPanelManager
@onready var temp_action_buttons: TempActionButtons = %TempActionButtons

@onready var top_bar: HBoxContainer = %TopBar
@onready var top_center_bar: HBoxContainer = %TopCenterBar
@onready var middle_bar: HBoxContainer = %MiddleBar
@onready var left_bar: VBoxContainer = %LeftBar
@onready var center_area_control: Control = %CenterControl
@onready var right_bar: VBoxContainer = %RightBar
@onready var bottom_bar: HBoxContainer = %BottomBar


func _ready() -> void:
	SystemManager.ui_system.ui = self
	%HomeButton.pressed.connect(open_projects_panel)
	%SaveButton.pressed.connect(func():
		SystemManager.save_data()
		PopupArrowPanelManager.get_from_ui_system().infomation_dialog("保存成功！", Vector2.ZERO)
	)
	
func open_projects_panel():
	const ProjectManagePanel = preload("res://scenes/project_manage_panel/project_manage_panel.gd")
	const PROJECT_MANAGE_PANEL = preload("res://scenes/project_manage_panel/project_manage_panel.tscn")
	SystemManager.save_data()
	var project_manage_panel = PROJECT_MANAGE_PANEL.instantiate() as ProjectManagePanel
	layers.add_child(project_manage_panel)
	project_manage_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	project_manage_panel.update_projects()


func set_main_panel_visible(value:bool):
	main_panel.visible = value
	temp_action_buttons.update()
