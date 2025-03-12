class_name UndoRedoSystem extends Node

signal undoredo_changed

var undoredo : UndoRedo

func _ready() -> void:
	undoredo = UndoRedo.new()
	undoredo.max_steps = 50
	undoredo.version_changed.connect(func():
		undoredo_changed.emit()
		#print(undoredo.get_version())
	)

func undo():
	if undoredo.has_undo():
		undoredo.undo()
		
func redo():
	if undoredo.has_redo():
		undoredo.redo()

func clear():
	undoredo.clear_history()
	undoredo_changed.emit()
#---------------------------------------------------------------------------------------------------
func add_undoredo(fn:Callable):
	#SystemManager.undoredo_system.add_undoredo(func(undoredo:UndoRedo):
		#undoredo.create_action("action_name", UndoRedo.MergeMode.MERGE_DISABLE, true)
		#undoredo.add_do_method(func():
			#pass
		#)
		#undoredo.add_undo_method(func():
			#pass
		#)
		#undoredo.commit_action(true)
	#)
	fn.call(undoredo)

func add_simple_undoredo(action_name:String, fn:Callable, backward_undo := true, execute:=false):
	undoredo.create_action(action_name, UndoRedo.MergeMode.MERGE_DISABLE, backward_undo)
	fn.call(undoredo)
	undoredo.commit_action(execute)

#---------------------------------------------------------------------------------------------------
func start_mergends_action(action_name:String, backward_undo := true):
	undoredo.create_action(action_name, UndoRedo.MergeMode.MERGE_ENDS, backward_undo)
	undoredo.start_force_keep_in_merge_ends()

func add_mergends_action(action_name:String, fn:Callable, backward_undo := true, execute:=false):
	undoredo.create_action(action_name, UndoRedo.MergeMode.MERGE_ENDS, backward_undo)
	fn.call(undoredo)
	undoredo.commit_action(execute)
	
func end_mergends_action(commit_action := false):
	undoredo.end_force_keep_in_merge_ends()
	undoredo.commit_action(commit_action)
	
#---------------------------------------------------------------------------------------------------
