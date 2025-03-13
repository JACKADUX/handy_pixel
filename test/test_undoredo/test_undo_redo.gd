extends Control

var undoredo := UndoRedo.new()

func _ready() -> void:
	
	merge(1)
	merge(2)
	#await get_tree().create_timer(1).timeout
	#merge(3)
	#undoredo.end_force_keep_in_merge_ends()
	print("## start undoredo")
	undoredo.undo()
	undoredo.redo()
	
	print("## history_count")
	print(undoredo.get_history_count())
	

func merge(value):
	undoredo.create_action("A", UndoRedo.MERGE_ENDS, false)
	undoredo.add_do_method(func():
		print("do %s"%str(value))
	)
	undoredo.add_undo_method(func():
		print("undo %s"%str(value))
	)
	undoredo.commit_action(true)
	
