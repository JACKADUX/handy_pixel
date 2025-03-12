class_name PopupArrowPanelManager extends Control

const PopupArrowPanel = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.gd")
const POPUP_ARROW_PANEL = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.tscn")

var _panels := {}

func _ready() -> void:
	SystemManager.ui_system.popup_arrow_panel_manager = self
	hide()

func get_or_create_popup_panel(contorl_panel_scene:PackedScene, free_panel_on_hide:bool=true) -> PopupArrowPanel:
	var panel
	if not free_panel_on_hide:
		panel = _panels.get(contorl_panel_scene)
		if not panel:
			panel = POPUP_ARROW_PANEL.instantiate()
			add_child(panel)
			panel.add_panel(contorl_panel_scene.instantiate())
			_panels[contorl_panel_scene] = panel
	else:
		panel = POPUP_ARROW_PANEL.instantiate()
		add_child(panel)
		panel.add_panel(contorl_panel_scene.instantiate())
	panel.hide()
	panel.free_panel_on_hide = free_panel_on_hide
	return panel

func show_popup_panel(contorl_panel_scene:PackedScene, free_panel_on_hide:bool=true) -> PopupArrowPanel:
	var panel = get_or_create_popup_panel(contorl_panel_scene, free_panel_on_hide)
	panel.show()
	show()
	return panel

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return 
	if event is InputEventMouseButton:
		for child in get_children():
			child.hide()
		hide()
