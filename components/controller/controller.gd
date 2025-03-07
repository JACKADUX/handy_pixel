extends Panel

signal direction_changed(value:Vector2)  # 0 ~ 1?

@onready var pointer: Panel = %Pointer

var pressed := false

var _radius :float:
	get: return size.x*0.5
var _dir : Vector2

func _ready() -> void:
	size.y = size.x

func _process(delta: float) -> void:
	if pressed:
		var dis = _get_global_center(self).distance_to(_get_global_center(pointer))
		direction_changed.emit(_dir*remap(dis, 0, _radius, 0, 1))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if (event.global_position - _get_global_center(self)).length() > _radius:
				return 
			pressed = true
			#accept_event()
		elif not event.is_pressed() and pressed:
			pressed = false
			var tween = create_tween()
			tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(pointer, "global_position", _get_global_center(self) - pointer.size*0.5, 0.2)
			#accept_event()
		
			
	elif event is InputEventMouseMotion and pressed:
		var v1 :Vector2 = event.global_position - _get_global_center(self)
		var dir :Vector2 = v1.normalized()
		_dir = dir
		if v1.length() < _radius:
			pointer.global_position = event.global_position - pointer.size*0.5
		else:
			pointer.global_position = _get_global_center(self) + dir * _radius - pointer.size*0.5
		#accept_event()

func _get_global_center(control:Control):
	return control.global_position + control.size * 0.5
