class_name PopupArrowPanelManager extends Control

const PopupArrowPanel = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.gd")
const POPUP_ARROW_PANEL = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.tscn")

var _panels := {}

static func get_from_ui_system() -> PopupArrowPanelManager:
	return SystemManager.ui_system.ui.popup_arrow_panel_manager

func _ready() -> void:
	show()
	set_block(false)

func set_block(value:bool):
	if value:
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
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
	set_block(true)
	return panel

func on_clean_notifyed():
	for child in get_children():
		if child.visible:
			return 
	set_block(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse and event.is_pressed():
		clear_tooltip_dialogs() # 有任何点击输入时关闭所有tooltip窗口

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.is_pressed():
		for child in get_children():
			child.hide()
		set_block(false)

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
	control.tree_exited.connect(func():
		on_clean_notifyed()
	)
	return control
	
const CONFIRM = preload("res://components/dialogs/confirm.tscn")
const ConfirmDialog = preload("res://components/dialogs/confirm_dialog.gd")
func confirm_dialog(pos:Vector2) -> ConfirmDialog:
	set_block(true)
	var dialog = CONFIRM.instantiate()
	var block_layer = new_block_layer(Color(Color.BLACK, 0.2))
	block_layer.add_child(dialog)
	
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
	
const InfomationDialog = preload("res://components/dialogs/infomation_dialog.gd")
const INFOMATION_DIALOG = preload("res://components/dialogs/infomation_dialog.tscn")
func infomation_dialog(text:String, pos:Vector2, delay:float=3) -> InfomationDialog:
	var dialog = INFOMATION_DIALOG.instantiate()
	add_child(dialog)
	dialog.z_index = 10
	dialog.label.text = text
	
	var center = get_rect().get_center()
	dialog.global_position = pos - dialog.get_rect().get_center()
	dialog.pivot_offset = dialog.size*0.5
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	tween.tween_property(dialog, "scale", Vector2.ZERO, 0.2).from(Vector2.ONE).set_delay(delay)
	tween.tween_callback(dialog.queue_free)
	dialog.tree_exited.connect(func():
		on_clean_notifyed()
	)
	return dialog

const TooltipDialog = preload("res://components/dialogs/tooltip_dialog.gd")
const TOOLTIP_DIALOG = preload("res://components/dialogs/tooltip_dialog.tscn")
const GROUP_TOOLTIP_DIALOG = "TooltipDiaglogGroup"
func clear_tooltip_dialogs():
	for dlg in get_tree().get_nodes_in_group(GROUP_TOOLTIP_DIALOG):
		dlg.queue_free()
		
func tooltip_dialog(title:String, tooltip:String, delay:float=3) -> TooltipDialog:
	clear_tooltip_dialogs()
	var dialog = TOOLTIP_DIALOG.instantiate()
	add_child(dialog)
	dialog.add_to_group(GROUP_TOOLTIP_DIALOG)
	dialog.z_index = 20
	dialog.set_tooltip(title, tooltip)
	
	var center = get_rect().get_center()
	# dialog.global_position = pos - dialog.get_rect().get_center()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 0)
	dialog.position += Vector2(96, -16)
	dialog.pivot_offset = Vector2(0, dialog.size.y)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	tween.tween_property(dialog, "scale", Vector2.ZERO, 0.2).from(Vector2.ONE).set_delay(delay)
	tween.tween_callback(dialog.queue_free)
	dialog.tree_exited.connect(func():
		on_clean_notifyed()
	)
	return dialog
