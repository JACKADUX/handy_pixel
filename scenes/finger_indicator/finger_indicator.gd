extends Control

@export var f1 :Control
@export var f2 :Control

var input_datas := InputDatas.new()

func _ready() -> void:
	#if not SystemManager.is_initialized():
		#await SystemManager.system_initialized
	#SystemManager.input_system.event_occurred.connect(func(event, data):
		#if event == InputRecognizer.EVENT_INPUT_HANDLED:
			#var input_recognizer = SystemManager.input_system.input_recognizer
			#var input_datas = input_recognizer.input_datas
			#var inputdata_1 = input_datas.get_input_data(0)
			#update_finger(inputdata_1, f1)
			#var inputdata_2 = input_datas.get_input_data(1)
			#update_finger(inputdata_2, f2)
	#)
	update_finger(null, f1)
	update_finger(null, f2)

func _input(event: InputEvent) -> void:
	var inputdata :InputData
	if OS.has_feature("editor") or OS.has_feature("windows"):
		if event is not InputEventMouseButton and event is not InputEventMouseMotion:
			return 
		var index = event.button_index if event is InputEventMouseButton else event.button_mask
		inputdata = input_datas.get_or_add_input_data(index)
		InputData.update_in_mouse(inputdata, event)
		if index == 1:
			update_finger(inputdata, f1)
		if index == 2:
			update_finger(inputdata, f2)	
				
	elif OS.has_feature("android"):
		if event is not InputEventScreenTouch and event is not InputEventScreenDrag:
			return 
		inputdata  = input_datas.get_or_add_input_data(event.index)
		InputData.update_in_touch(inputdata, event)
		if event.index == 0:
			update_finger(inputdata, f1)
		if event.index == 1:
			update_finger(inputdata, f2)	
			
func update_finger(inputdata:InputData, finger:Control):
	if inputdata:
		if inputdata.is_just_pressed():
			finger.show()
		elif not inputdata.is_pressed():
			finger.hide()
		if inputdata.is_pressed() or inputdata.is_draged():
			finger.position = inputdata.end_position-finger.size*0.5
	else:
		finger.hide()
