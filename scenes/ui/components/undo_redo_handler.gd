extends Node


@export var undo_button: Button
@export var redo_button: Button


func _ready() -> void:
	SystemManager.undoredo_system.undoredo_changed.connect(update)
	undo_button.pressed.connect(func():
		SystemManager.undoredo_system.undo()
	)
	redo_button.pressed.connect(func():
		SystemManager.undoredo_system.redo()
	)
	update()
	
func update():
	undo_button.disabled = not SystemManager.undoredo_system.undoredo.has_undo()
	redo_button.disabled = not SystemManager.undoredo_system.undoredo.has_redo()
