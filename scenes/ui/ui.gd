extends Control

@onready var main_panel: MarginContainer = %MainPanel
@onready var layers: Control = %Layers  # 用来新增页面 比如 ProjectManagePanel
@onready var tool_ui_control: ToolUIControl = %ToolUIControl
@onready var popup_arrow_panel_manager: PopupArrowPanelManager = %PopupArrowPanelManager

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

func hide_all_except_bottom():
	top_bar.hide()
	top_center_bar.hide()
	middle_bar.hide()
	left_bar.hide()
	center_area_control.hide()
	right_bar.hide()
	bottom_bar.show()

func show_all():
	top_bar.show()
	top_center_bar.show()
	middle_bar.show()
	left_bar.show()
	center_area_control.show()
	right_bar.show()
	bottom_bar.show()
	
func open_projects_panel():
	const ProjectManagePanel = preload("res://scenes/project_manage_panel/project_manage_panel.gd")
	const PROJECT_MANAGE_PANEL = preload("res://scenes/project_manage_panel/project_manage_panel.tscn")
	SystemManager.save_data()
	var project_manage_panel = PROJECT_MANAGE_PANEL.instantiate() as ProjectManagePanel
	layers.add_child(project_manage_panel)
	project_manage_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	project_manage_panel.update_projects()
