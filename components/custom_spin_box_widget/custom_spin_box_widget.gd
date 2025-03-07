@tool
class_name CustomSpinBoxWidget extends PanelContainer

signal value_changed(value:float)

@onready var label: Label = %Label

@onready var left_button: TextureButton = %LeftButton
@onready var right_button: TextureButton = %RightButton

@onready var v_separator_l: VSeparator = %VSeparatorL
@onready var v_separator_r: VSeparator = %VSeparatorR


@onready var lv_box_container: VBoxContainer = %LVBoxContainer
@onready var l_top_button: TextureButton = %LTopButton
@onready var l_bottom_button: TextureButton = %LBottomButton

@onready var r_top_button: TextureButton = %RTopButton
@onready var r_bottom_button: TextureButton = %RBottomButton
@onready var rv_box_container: VBoxContainer = %RVBoxContainer

enum WidgetLayoutMode {LTB, RTB, LR}
@export var widget_layout_mode := WidgetLayoutMode.LR:
	set(value):
		widget_layout_mode = value
		if is_inside_tree():
			set_widget_layout_mode(widget_layout_mode)
		
@export var increment := 1
@export var value :float = 0
@export var min_value := 1
@export var max_value := 2048
@export var rounded := true
@export var drag_factor := 0.1

var _update_start := false

var _time_pressed :float= 0
var _pressed_label := false
var _pressed_value = 0
var _delta_value = 0

var increase_button : TextureButton
var decrease_button : TextureButton

func _ready() -> void:
	
	set_widget_layout_mode(widget_layout_mode)
	
	match widget_layout_mode:
		WidgetLayoutMode.LTB:
			increase_button = l_top_button
			decrease_button = l_bottom_button
		WidgetLayoutMode.RTB:
			increase_button = r_top_button
			decrease_button = r_bottom_button
		WidgetLayoutMode.LR:
			increase_button = right_button
			decrease_button = left_button
	
	decrease_button.button_down.connect(func():
		_update_start = true
		_time_pressed = 0
	)
	decrease_button.button_up.connect(func():
		_update_start = false
		set_value(value -increment)
		value_changed.emit(value)
	)
	
	increase_button.button_down.connect(func():
		_update_start = true
		_time_pressed = 0
	)

	increase_button.button_up.connect(func():
		_update_start = false
		set_value(value +increment)
		value_changed.emit(value)
	)
	
	label.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton:
			_pressed_label = event.pressed
			_pressed_value = value
			_delta_value = event.position
		if event is InputEventMouseMotion and _pressed_label:
			var ofsv = event.position-_delta_value
			var ofs = ofsv.x if widget_layout_mode == WidgetLayoutMode.LR else -ofsv.y
			set_value(_pressed_value + ofs *drag_factor)
			value_changed.emit(value)
	)
	set_value(value)
	
		
func _process(delta: float) -> void:
	if _update_start:
		_time_pressed += delta
		var inc = increment
		if _time_pressed < 0.5:
			return 
		if decrease_button.button_pressed:
			set_value(value -inc)
			value_changed.emit(value)
		elif increase_button.button_pressed:
			set_value(value +inc)
			value_changed.emit(value)

func auto_mode():
	var area_type_lr := LayoutHelper.get_area_type_lr(get_global_rect(), get_viewport_rect())
	var value = WidgetLayoutMode.LR
	match area_type_lr:
		LayoutHelper.AreaTypeLR.LEFT:
			value = WidgetLayoutMode.LTB
		LayoutHelper.AreaTypeLR.RIGHT:
			value = WidgetLayoutMode.RTB
	set_widget_layout_mode(value)

func set_widget_layout_mode(value:WidgetLayoutMode):
	lv_box_container.hide()
	rv_box_container.hide()
	left_button.hide()
	right_button.hide()
	v_separator_l.hide()
	v_separator_r.hide()
	match value:
		WidgetLayoutMode.LTB:
			lv_box_container.show()
			v_separator_l.show()
		WidgetLayoutMode.RTB:
			rv_box_container.show()
			v_separator_r.show()
		WidgetLayoutMode.LR:
			left_button.show()
			right_button.show()
			v_separator_l.show()
			v_separator_r.show()
	
func get_value():
	return value
	
func set_value(p_value:float):
	value = clamp(p_value, min_value, max_value)
	if rounded:
		var int_value := int(value)
		label.text = str(int_value)
	else:
		label.text = str(value)
