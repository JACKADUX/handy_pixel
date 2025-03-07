extends PanelContainer

signal ok_pressed
signal cancel_pressed

@onready var ok_button: Button = %OkButton
@onready var cancel_button: Button = %CancelButton

func _ready() -> void:
	ok_button.pressed.connect(func(): ok_pressed.emit())
	cancel_button.pressed.connect(func(): cancel_pressed.emit())
