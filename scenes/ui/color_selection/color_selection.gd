extends VBoxContainer

signal value_changed(value)

@onready var color_palette_panel = %ColorPalettePanel
@onready var color_pickers_panel = %ColorPickersPanel

func _ready() -> void:
	color_palette_panel.value_changed.connect(func(v):
		value_changed.emit(v)
	)
	color_pickers_panel.value_changed.connect(func(v):
		value_changed.emit(v)
	)
