extends VBoxContainer

signal value_changed(value)

@onready var r_tracer: Control = %RTracer
@onready var r_label: Label = %RLabel
@onready var g_tracer: Control = %GTracer
@onready var g_label: Label = %GLabel
@onready var b_tracer: Control = %BTracer
@onready var b_label: Label = %BLabel
@onready var a_tracer: Control = %AlphaTracer
@onready var a_label: Label = %ALabel
@onready var final_color: ColorRect = %FinalColor

var _color = Color.WHITE
var _prev_h :float = 0
var _prev_s :float = 0

func _ready() -> void:
	for tracer in [r_tracer, g_tracer, b_tracer, a_tracer]:
		tracer.drag_ended.connect(func():
			value_changed.emit(get_value())
		)
	
	r_tracer.location_changed.connect(func():
		var value = r_tracer.get_location().x
		if value == 1:
			value = 0.99999  # NOTE:如果是1则会自动回到0
		_color.h = value
		_prev_h = value
		_update()
	)
	g_tracer.location_changed.connect(func():
		var value = g_tracer.get_location().x
		_color.s = value
		_prev_s = value
		if value != 0:
			_color.h = _prev_h
		_update()
	)
	b_tracer.location_changed.connect(func():
		var value = b_tracer.get_location().x
		_color.v = value
		if value != 0:
			_color.s = _prev_s
			_color.h = _prev_h
		_update()
	)
	a_tracer.location_changed.connect(func():
		var value = a_tracer.get_location().x
		_color.a = value
		_update()
	)
	
	
	
	_update()
	
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
	
	r_label.text = "H %d"%[h*360]
	g_label.text = "S %d"%[s*100]
	b_label.text = "V %d"%[_color.v*100]
	a_label.text = "A %d"%[_color.a8]
	r_tracer.set_location(Vector2(h,1))
	g_tracer.set_location(Vector2(s,1))
	b_tracer.set_location(Vector2(_color.v,1))
	a_tracer.set_location(Vector2(_color.a,1))
	final_color.color = _color
	
	r_tracer.get_parent().material.set_shader_parameter("saturation", s)
	r_tracer.get_parent().material.set_shader_parameter("value", _color.v)
	set_shader_color(g_tracer, saturation(_color, 0), saturation(_color, 1))
	set_shader_color(b_tracer, color_value(_color, 0), color_value(_color, 1))

func saturation(color, v):
	color.s = v
	color.h = _get_h()
	return color

func color_value(color, v):
	color.v = v
	color.s = _get_s()
	color.h = _get_h()
	return color

func set_shader_color(tracer:Node, c1:Color, c2:Color):
	tracer.get_parent().set_instance_shader_parameter("c1", c1)
	tracer.get_parent().set_instance_shader_parameter("c2", c2)
	
