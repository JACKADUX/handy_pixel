extends fnPool

static func mouse_down_and_up(control:Control, args:=[], kwargs:={}):
	if not kwargs.has("is_pressed"):
		return
	_pivot_offset(control)
	var tween = base_tween(Tween.EASE_OUT, Tween.TRANS_BACK)
	if kwargs.get("is_pressed"):
		tween.tween_property(control, "scale", Vector2.ONE*args[1], args[0])
	else:
		tween.tween_property(control, "scale", Vector2.ONE*args[2], args[0])
