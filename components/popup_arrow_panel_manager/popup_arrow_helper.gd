extends Node

@export var popup_panel_scene : PackedScene
@export var popup_side :Side
@export var offset :int = 96
@export var panel_offset := Vector2(0,0)
@export var free_panel_on_hide := false

func _ready() -> void:
	var parent = get_parent()
	if parent is not Button:
		return 
	parent.pressed.connect(func():
		var arrow_panel = PopupArrowPanelManager.get_from_ui_system().show_popup_panel(popup_panel_scene, free_panel_on_hide)
		arrow_panel.set_popup_side(popup_side, -panel_offset)
		var offset = Vector2.from_angle(PI*0.5*int(popup_side)) * offset
		arrow_panel.global_position = parent.get_global_rect().get_center() - offset + panel_offset
		arrow_panel.pivot_offset = arrow_panel.triangle.position
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(arrow_panel, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
	)
	
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	if not free_panel_on_hide:
		PopupArrowPanelManager.get_from_ui_system().get_or_create_popup_panel(popup_panel_scene, free_panel_on_hide)

func get_popup_arrow_panel() -> PopupArrowPanelManager.PopupArrowPanel:
	return PopupArrowPanelManager.get_from_ui_system().get_popup_panel(popup_panel_scene)

	
