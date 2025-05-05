extends VBoxContainer

signal value_changed(value:Color)
signal drag_started
signal drag_ended

@onready var sv_rect = %SVRect
@onready var alpha_rect = %AlphaRect
@onready var final_color = %FinalColor

@onready var sv_tracer = %SVTracer
@onready var hue_tracer = %HueTracer
@onready var alpha_tracer = %AlphaTracer

@onready var h_label: Label = %HLabel
@onready var a_label: Label = %ALabel



var _color = Color.WHITE
var _prev_h :float = 0
var _prev_s :float = 0


#---------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------
func _ready():
	sv_tracer.location_changed.connect(func():
		var value = sv_tracer.get_location()
		var s = value.x
		var v = 1-value.y
		_prev_s = s
		_color.s = s
		_color.v = v
		if s != 0 and v != 0:
			_color.s = _prev_s
			_color.h = _prev_h
		_update()
	)
	hue_tracer.location_changed.connect(func():
		var value = hue_tracer.get_location().y
		if value == 1:
			value = 0.99999
		_color.h = value
		_prev_h = value
		_update()
	)
	alpha_tracer.location_changed.connect(func():
		var value = alpha_tracer.get_location().x
		_color.a = value
		_update()
	)
	
	for tracer in [sv_tracer, hue_tracer, alpha_tracer]:
		tracer.drag_started.connect(func():
			drag_started.emit()
		)
		tracer.drag_ended.connect(func():
			value_changed.emit(final_color.color)
			drag_ended.emit()
		)
	
	_update()

#---------------------------------------------------------------------------------------------------
func set_value(value:Color):
	_color = value
	if value.s != 0 and value.v != 0:
		_prev_h = value.h
		_prev_s = value.s
	_update()
	
func get_value() -> Color:
	return _color

func _get_s():
	return _color.s if _color.s != 0 else _prev_s

func _get_h():
	return _color.h if _color.h != 0 else _prev_h
	
func _update():
	var h = _get_h()
	var s = _get_s()
	h_label.text = "H %d"%[h*360]
	a_label.text = "A %d"%[_color.a8]
	hue_tracer.set_location(Vector2(0,h))
	alpha_tracer.set_location(Vector2(_color.a,1))
	sv_tracer.set_location(Vector2(s,1-_color.v))
	sv_tracer.fill_color = Color(_color,1)
	
	var mat = sv_tracer.get_parent().material
	mat.set_shader_parameter("h", h)
	mat.set_shader_parameter("s", s)
	mat.set_shader_parameter("v", _color.v)
	
	final_color.color = _color
