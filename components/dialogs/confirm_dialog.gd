extends PanelContainer

signal confirmed
signal canceled

func _ready() -> void:
	get_node('%ConfirmButton').pressed.connect(func(): confirmed.emit())
	get_node('%CancelButton').pressed.connect(func(): canceled.emit())
