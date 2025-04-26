class_name InputData

var start_position: Vector2
var end_position: Vector2
var relative : Vector2
var pressed:=false
var draged:= false
var double_clicked := false

func _to_string() -> String:
	return JSON.stringify({
		"start_position":start_position,
		"end_position":end_position,
		"relative":relative,
		"pressed":pressed,
		"draged":draged,
		"double_clicked":double_clicked,
	})

func is_pressed() -> bool:
	return pressed

func is_draged() -> bool:
	return draged

func is_just_pressed() -> bool:
	return pressed and not draged

func clear():
	start_position= Vector2.ZERO
	end_position =  Vector2.ZERO
	relative = Vector2.ZERO
	pressed = false
	draged = false
	double_clicked = false

func duplicate() -> InputData:
	var fd = InputData.new()
	fd.start_position = start_position
	fd.end_position = end_position
	fd.relative = relative
	fd.pressed = pressed
	fd.draged = draged
	fd.double_clicked = double_clicked
	return fd

static func update_in_mouse(inputdata:InputData, event:InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			# 记录触摸点
			inputdata.clear()
			inputdata.start_position = event.position
			inputdata.end_position = event.position
			inputdata.pressed = true
		else:
			# 移除离开的触摸点
			inputdata.pressed = false
		inputdata.double_clicked = event.double_click
	if event is InputEventMouseMotion:
		inputdata.end_position = event.position
		inputdata.relative = event.relative
		inputdata.draged = true
		
static func update_in_touch(inputdata:InputData, event:InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			# 记录触摸点
			inputdata.clear()
			inputdata.start_position = event.position
			inputdata.end_position = event.position
			inputdata.pressed = true
		else:
			# 移除离开的触摸点
			inputdata.pressed = false
		inputdata.double_clicked = event.double_tap
	if event is InputEventScreenDrag:
		inputdata.end_position = event.position
		inputdata.relative = event.relative
		inputdata.draged = true
