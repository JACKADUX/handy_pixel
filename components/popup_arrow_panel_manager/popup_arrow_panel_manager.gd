class_name PopupArrowPanelManager extends Control

const PopupArrowPanel = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.gd")
const POPUP_ARROW_PANEL = preload("res://components/popup_arrow_panel_manager/popup_arrow_panel.tscn")

var _panels := {}

static func get_from_ui_system() -> PopupArrowPanelManager:
	return SystemManager.ui_system.ui.popup_arrow_panel_manager

func _ready() -> void:
	show()
	set_block(false)
	register_plugins()

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

func custom_popup(control:Control):
	var block_layer = new_block_layer(Color(Color.BLACK, 0.2))
	block_layer.add_child(control)
	return block_layer
	
func add_panel_container(control:Control, margin:=24):
	var contanier = PanelContainer.new()
	contanier.theme_type_variation = "popup_panel"
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", margin)
	margin_container.add_theme_constant_override("margin_top", margin)
	margin_container.add_theme_constant_override("margin_right", margin)
	margin_container.add_theme_constant_override("margin_bottom", margin)
	contanier.add_child(margin_container)
	margin_container.add_child(control)
	return contanier

func quick_popup_tween(control:Control, type:=0):
	match type:
		0:
			control.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
			control.pivot_offset = control.size*0.5
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(control, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	

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
	
	dialog.confirmed.connect(func():
		block_layer.queue_free()
	)
	dialog.canceled.connect(func():
		block_layer.queue_free()
	)
	return dialog
	
const InfomationDialog = preload("res://components/dialogs/infomation_dialog.gd")
const INFOMATION_DIALOG = preload("res://components/dialogs/infomation_dialog.tscn")
const GROUP_INFORMATION_DIALOG = "InformationDiaglogGroup"
func clear_information_dialogs():
	for dlg in get_tree().get_nodes_in_group(GROUP_INFORMATION_DIALOG):
		dlg.queue_free()
		
func infomation_dialog(text:String, pos:Vector2, delay:float=1) -> InfomationDialog:
	var dialog = INFOMATION_DIALOG.instantiate()
	add_child(dialog)
	dialog.add_to_group(GROUP_INFORMATION_DIALOG)
	dialog.z_index = 10
	dialog.label.text = text
	dialog.global_position = pos - dialog.get_rect().get_center()
	dialog.pivot_offset = dialog.size*0.5
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dialog, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	tween.tween_property(dialog, "scale", Vector2.ZERO, 0.2).from(Vector2.ONE).set_delay(delay)
	tween.tween_callback(dialog.queue_free)
	dialog.tree_exited.connect(func():
		on_clean_notifyed()
	)
	return dialog

func quick_notify_dialog(text:String, delay:float=1):
	clear_information_dialogs()
	infomation_dialog(text, size*0.5, delay)

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

## Plugin
var _plugins := {}
const PopupPanelPlugin = preload("res://components/popup_arrow_panel_manager/popup_panel_plugin.gd")
func register_plugins():
	for child in get_children():
		if child is not PopupPanelPlugin:
			continue
		_plugins[child.plugin_name] = child.packed_scene
		child.queue_free()
		
func call_popup_panel_plugin(plugin_name:String) -> Control:
	var packed_scene = _plugins.get(plugin_name)
	if not packed_scene:
		printerr("call_popup_panel_plugin失败 plugin_name: '%s' 不存在"%plugin_name)
		return 
	var panel :Control= packed_scene.instantiate()
	var block_layer = new_block_layer(Color(Color.BLACK, 0.2))
	var panel_container = add_panel_container(panel)
	block_layer.add_child(panel_container)
	
	panel_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel_container.pivot_offset = panel_container.size*0.5
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)

	panel.tree_exited.connect(func():
		block_layer.queue_free()
	)
	return panel
