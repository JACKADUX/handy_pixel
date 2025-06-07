extends PanelContainer

signal confirmed
signal canceled

func _ready() -> void:
	%ConfirmButton.pressed.connect(func(): confirmed.emit())
	%CancelButton.pressed.connect(func(): canceled.emit())
