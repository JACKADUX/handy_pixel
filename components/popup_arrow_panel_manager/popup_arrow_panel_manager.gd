class_name PopupArrowPanelManager extends Control

const PopupArrowPanel = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.gd")
const POPUP_ARROW_PANEL = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.tscn")

var _panels := {}

func _ready() -> void:
	SystemManager.ui_system.popup_arrow_panel_manager = self
	hide()

func get_popup_panel(contorl_panel_scene:PackedScene) -> PopupArrowPanel:
	return _panels.get(contorl_panel_scene)
	
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

const CONFIRM = preload("res://components/dialogs/confirm.tscn")
const ConfirmDialog = preload("res://components/dialogs/confirm_dialog.gd")
func confirm_dialog(pos:Vector2) -> ConfirmDialog:
	var dialog = CONFIRM.instantiate()
	var block_layer = new_block_layer(Color(Color.BLACK, 0.2))
	block_layer.add_child(dialog)
	
	var center = block_layer.get_rect().get_center()
	dialog.global_position = pos - dialog.get_rect().get_center()
	dialog.pivot_offset = dialog.size*0.5
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	
	dialog.confirm_button.pressed.connect(func():
		block_layer.queue_free()
	)
	dialog.cancel_button.pressed.connect(func():
		block_layer.queue_free()
	)
	return dialog
	

func new_block_layer(color:=Color.BLACK) -> ColorRect:
	var control = ColorRect.new()
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.color = color
	add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	control.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.is_pressed():
			control.queue_free()
	)
	return control
	
