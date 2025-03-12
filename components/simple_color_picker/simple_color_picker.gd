class_name SimpleColorPicker extends MarginContainer

signal value_changed(value:Color)

@onready var color_rect = %ColorRect
@onready var color_hue_bar = %ColorHueBar
@onready var color_transparent = %ColorTransparent
@onready var color_final = %ColorFinal
@onready var line_edit = %LineEdit
@onready var color_prev = %ColorPrev
@onready var button_go_back = %ButtonGoBack


@export var radius :float= 16.0
@export var current_color := Color.WHITE
@export var valid_h :float= 0
@export var valid_s :float= 0
@export var valid_v :float= 0

var color_sv_pos :Vector2:
	get: return Vector2(valid_s, 1-valid_v)

var color_h_pos :Vector2:
	get: return Vector2(0, valid_h)
	
var color_t_pos :Vector2:
	get: return Vector2(current_color.a, 0)

#---------------------------------------------------------------------------------------------------
func _ready():
	var sv_tracer = color_rect.get_child(0) as HandleTracer
	sv_tracer.beacon_located.connect(func(v):
		valid_v = 1-v.y# 如果v变成0则s也会变成0
		valid_s = v.x
		update_color()
	)
	sv_tracer.draw.connect(func():
		sv_tracer.draw_circle(color_sv_pos*sv_tracer.size, radius, Color(0.5,0.5,0.5), true, -1, true)
		sv_tracer.draw_circle(color_sv_pos*sv_tracer.size, radius-2, Color(current_color,1), true, -1,  true)
	)
	
	var hue_tracer = color_hue_bar.get_child(0) as HandleTracer
	hue_tracer.beacon_located.connect(func(v):
		valid_h = v.y
		update_color()
	)
	hue_tracer.draw.connect(func():
		var rect = Rect2(color_h_pos*hue_tracer.size.y, Vector2(hue_tracer.size.x, 4))
		rect.position.y = min(rect.position.y, hue_tracer.size.y-4)
		hue_tracer.draw_rect(rect, Color.BLACK, true, -1, true)
		var c = Color.AQUAMARINE
		c.h = valid_h
		c.s = 1
		c.v = 1
		hue_tracer.draw_rect(rect.grow(-1), c, true, -1, true)
	)
	
	var tsp_tracer = color_transparent.get_child(0) as HandleTracer
	tsp_tracer.beacon_located.connect(func(v):
		current_color.a = v.x
		update_color()
	)
	tsp_tracer.draw.connect(func():
		var rect = Rect2(color_t_pos*tsp_tracer.size.x, Vector2(4, tsp_tracer.size.y))
		rect.position.x = min(rect.position.x, tsp_tracer.size.x-4)
		tsp_tracer.draw_rect(rect, Color.BLACK, false, 1, true)
		var c = Color(1,1,1, current_color.a)
		tsp_tracer.draw_rect(rect.grow(-1), c, true, -1, true)
	)
	
	for tracer in [sv_tracer, hue_tracer, tsp_tracer]:
		tracer.drag_started.connect(func():
			color_prev.color = current_color
		)
		tracer.drag_ended.connect(func():
			if current_color != color_prev.color:
				value_changed.emit(current_color)
		)
		
	button_go_back.pressed.connect(func():
		set_color(color_prev.color)
		value_changed.emit(current_color)
	)
	
	line_edit.text_submitted.connect(func(v:String):
		var _current_color = Color.from_string(v, Color.WHITE)
		if _current_color != color_prev.color:
			set_color(_current_color)
			value_changed.emit(_current_color)
	)
	
	color_prev.color = Color.WHITE
	set_color(current_color)
	
#---------------------------------------------------------------------------------------------------
func set_color(value:Color):
	color_prev.color = current_color
	current_color = value
	valid_h = current_color.h
	valid_s = current_color.s
	valid_v = current_color.v
	update_color()	
	
#---------------------------------------------------------------------------------------------------
func update_color():
	
	current_color.h = valid_h
	current_color.s = valid_s
	current_color.v = valid_v
	
	var sv_tracer = color_rect.get_child(0) as HandleTracer
	var hue_tracer = color_hue_bar.get_child(0) as HandleTracer
	var tsp_tracer = color_transparent.get_child(0) as HandleTracer
	color_transparent.self_modulate = current_color
	
	sv_tracer.queue_redraw()
	hue_tracer.queue_redraw()
	tsp_tracer.queue_redraw()
	
	color_final.color = current_color
	
	color_rect.material.set_shader_parameter("h", valid_h)
	line_edit.text = current_color.to_html(current_color.a != 1.0)


	
	
	
	
