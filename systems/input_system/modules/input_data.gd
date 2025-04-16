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
