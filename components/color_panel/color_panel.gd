class_name ColorPanel extends Panel

signal pressed

@export var color := Color.WHITE
@export var scale_factor := 0.8

var _stylebox = StyleBoxFlat.new()
var _hold := false
var _dt := 0
var _dpos := Vector2.ZERO

var _active:= false

func _ready() -> void:
	#_stylebox.set_border_width_all(6)
	#_stylebox.set_corner_radius_all(12)
	_stylebox.border_color = ThemeDB.get_project_theme().get_color("color_bg_base", "COLORS")
	add_theme_stylebox_override("panel", _stylebox)
	set_color(color)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
func set_color(value:Color):
	color = value
	_stylebox.bg_color = color
	
func get_color() -> Color:
	return color

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed() :
		_hold = true
		_dt = Time.get_ticks_msec()
		_dpos = event.position  # NOTE: 触屏上不能使用get_global_mouse_position() 会有误差
		
	if _hold and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_released() :
		_hold = false
		_dt = (Time.get_ticks_msec()- _dt)/1000.0
		_dpos = event.position-_dpos
		if _dpos.length() > 50 or _dt > 1:
			return 
		pressed.emit()
		
func activate():
	if _active:
		return
	_active = true
	pivot_offset = size*0.5
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale_factor * Vector2.ONE, 0.2)
	tween.tween_method(func(v):
		_stylebox.set_corner_radius_all(v*12)
		_stylebox.set_border_width_all(v*6)
		,
		0., 1., 0.2
	)
	
func deactivate():
	if not _active:
		return
	_active = false
	pivot_offset = size*0.5
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.tween_method(func(v):
		_stylebox.set_corner_radius_all(v*12)
		_stylebox.set_border_width_all(v*6)
		,
		1., 0., 0.2
	)
