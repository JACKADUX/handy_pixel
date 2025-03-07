class_name PopupArrowPanelManager extends Control

const PopupArrowPanel = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.gd")
const POPUP_ARROW_PANEL = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.tscn")

func _ready() -> void:
	SystemManager.ui_system.popup_arrow_panel_manager = self
	hide()

func new_popup_panel(contorl_panel:Control) -> PopupArrowPanel:
	var panel = POPUP_ARROW_PANEL.instantiate()
	add_child(panel)
	panel.add_panel(contorl_panel)
	show()
	return panel

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return 
	if event is InputEventMouseButton:
		for child in get_children():
			child.queue_free()
		hide()
