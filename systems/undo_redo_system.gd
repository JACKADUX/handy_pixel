class_name UndoRedoSystem extends Node

var undoredo : UndoRedo

func _ready() -> void:
	undoredo = UndoRedo.new()
	undoredo.max_steps = 50

#---------------------------------------------------------------------------------------------------
func clear():
	undoredo.clear_history()

#---------------------------------------------------------------------------------------------------
func simple_action(action_name: String, do_fn: Callable, undo_fn: Callable, merge_mode := UndoRedo.MergeMode.MERGE_DISABLE, backward_undo := true):
	undoredo.create_action(action_name, merge_mode, backward_undo)
	undoredo.add_do_method(do_fn)
	undoredo.add_undo_method(undo_fn)
	undoredo.commit_action()

#---------------------------------------------------------------------------------------------------
func bundle_actions(action_name: String, bundle_fn: Callable, merge_mode := UndoRedo.MergeMode.MERGE_DISABLE, backward_undo := true):
	# NOTE: bundle_fn 里应该包含  undoredo.add_do_method 和 undoredo.add_undo_method
	# WARNING : 使用 bundle_actions 时要注意 bundle_fn 中的undoredo方法会在 下方的 commit_action 后才会调用
	undoredo.create_action(action_name, merge_mode, backward_undo)
	bundle_fn.call()
	undoredo.commit_action()

#---------------------------------------------------------------------------------------------------
func append_action(action_fn: Callable, merge_mode := UndoRedo.MergeMode.MERGE_ALL, backward_undo := true):
	# 使用上一个action的名称添加都后面
	undoredo.create_action(undoredo.get_current_action_name(), merge_mode, backward_undo)
	action_fn.call()
	undoredo.commit_action()

func undo():
	if undoredo.has_undo():
		undoredo.undo()
		
func redo():
	if undoredo.has_redo():
		undoredo.redo()
