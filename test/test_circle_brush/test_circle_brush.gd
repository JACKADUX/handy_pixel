extends Control
var psize = 1
var shrink = 1
@onready var label: Label = $Label

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var s = 50
	var points = PencilData.generate_circle_brush(psize, shrink)
	var ofs = 0
	for p in points:
		draw_rect(Rect2((p+Vector2.ONE)*s, Vector2(s,s)).grow(-1), Color.WHITE, true)
	#points = PencilData.generate_circle_brush_outline(psize)
	#for p in points:
		#draw_rect(Rect2(p*s, Vector2(s,s)).grow(-1), Color(Color.BLACK, 0.5), true)
	


func _on_spin_box_value_changed(value: float) -> void:
	psize = value


func _on_h_slider_value_changed(value: float) -> void:
	shrink = value/100
	label.text = str(value)
