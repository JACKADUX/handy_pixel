extends ViewAdapter

var buttons :Array[Button]

func adapt_view(): 
	buttons.assign(view.get_children().filter(func(b): return b is Button))
	for button in buttons:
		button.toggled.connect(func(toggled_on:bool):
			value_changed.emit(get_value())
		)

func get_value() -> Variant: 
	return buttons.map(func(b): return int(b.button_pressed))

func set_value(value:Variant):
	var index = 0
	for button in buttons:
		button.set_pressed_no_signal(value[index])
		index += 1
