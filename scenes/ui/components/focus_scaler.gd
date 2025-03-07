extends Node

@export var scale_factor :float = 1.2

func _ready() -> void:
	var parent :Control = get_parent()
	parent.focus_entered.connect(func():
		if parent.disabled:
			return 
		parent.pivot_offset = parent.size*0.5
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(parent, "scale", Vector2.ONE*scale_factor, 0.1)
	)
	parent.focus_exited.connect(func():
		parent.pivot_offset = parent.size*0.5
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(parent, "scale", Vector2.ONE, 0.1)
	)
	
	
