extends Node

@export var button : Button
@export var reactor : Control
@export var factor :float= 1.2

func _ready() -> void:
	if not button :
		return 
	if not reactor:
		reactor = get_parent()
		
	button.mouse_entered.connect(func():
		if not button.disabled and factor != reactor.scale.x:
			reactor.pivot_offset = reactor.size*0.5
			tween_scale(reactor, factor)
	)
	
	button.mouse_exited.connect(func():
		if 1 != reactor.scale.x:
			reactor.pivot_offset = reactor.size*0.5
			tween_scale(reactor, 1)
	)
	
func tween_scale(node:Control, scale_factor:float=1, duration:=0.2):
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "scale", Vector2.ONE*scale_factor, duration)
