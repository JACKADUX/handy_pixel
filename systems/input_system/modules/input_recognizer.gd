class_name InputRecognizer

signal double_clicked(position:Vector2)
signal hovered(relative:Vector2)
signal paned(relative:Vector2)
signal zoomed(center:Vector2, factor:float)

signal pressed(input_data:InputData)
signal draged(input_data:InputData)

signal state_changed

# TODO: 把当前的状态用图标表示在用户界面
enum State {NONE, HOVER, PAN, ZOOM}
var state := State.NONE :
	set(value):
		if state == value:
			return 
		state = value
		state_changed.emit()

func bind_to_input_system(input_system:InputSystem):
	double_clicked.connect(input_system.double_clicked.emit)

	hovered.connect(input_system.hovered.emit)
	paned.connect(input_system.paned.emit)
	zoomed.connect(input_system.zoomed.emit)
	state_changed.connect(func():
		input_system.state = state
	)
	pressed.connect(input_system.pressed.emit)
	draged.connect(input_system.draged.emit)

func get_input_data(index:=0) -> InputData:
	return null

class InputData:
	var index : int
	var start_position: Vector2
	var end_position: Vector2
	var relative : Vector2
	var pressed:=false
	var draged:= false
	
	func _init(p_index:int) -> void:
		index = p_index
	
	func clear():
		start_position= Vector2.ZERO
		end_position =  Vector2.ZERO
		relative = Vector2.ZERO
		pressed = false
		draged = false
	
	func is_first() -> bool:
		return index == 0
		
	func is_seconed() -> bool:
		return index == 1
		
	func is_pressed() -> bool:
		return pressed
	
	func duplicate() -> InputData:
		var fd = InputData.new(index)
		fd.start_position = start_position
		fd.end_position = end_position
		fd.relative = relative
		fd.pressed = pressed
		fd.draged = draged
		return fd
