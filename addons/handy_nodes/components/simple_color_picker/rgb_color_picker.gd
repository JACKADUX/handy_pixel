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

func _ready() -> void:
	for tracer in [r_tracer, g_tracer, b_tracer, a_tracer]:
		tracer.drag_ended.connect(func():
			value_changed.emit(get_value())
		)
	r_tracer.location_changed.connect(func():
		var value = r_tracer.get_location().x
		_color.r = value
		_update()
	)
	g_tracer.location_changed.connect(func():
		var value = g_tracer.get_location().x
		_color.g = value
		_update()
	)
	b_tracer.location_changed.connect(func():
		var value = b_tracer.get_location().x
		_color.b = value
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
	_update()
	
func get_value() -> Color:
	return _color
	
func _update():
	r_label.text = "R %d"%[_color.r8]
	g_label.text = "G %d"%[_color.g8]
	b_label.text = "B %d"%[_color.b8]
	a_label.text = "A %d"%[_color.a8]
	r_tracer.set_location(Vector2(_color.r,1))
	g_tracer.set_location(Vector2(_color.g,1))
	b_tracer.set_location(Vector2(_color.b,1))
	a_tracer.set_location(Vector2(_color.a,1))
	final_color.color = _color
	
	set_shader_color(r_tracer, Color(0, _color.g, _color.b), Color(1, _color.g, _color.b))
	set_shader_color(g_tracer, Color(_color.r, 0, _color.b), Color(_color.r, 1, _color.b))
	set_shader_color(b_tracer, Color(_color.r, _color.g, 0), Color(_color.r, _color.g, 1))

func set_shader_color(tracer:Node, c1:Color, c2:Color):
	tracer.get_parent().set_instance_shader_parameter("c1", c1)
	tracer.get_parent().set_instance_shader_parameter("c2", c2)
	
