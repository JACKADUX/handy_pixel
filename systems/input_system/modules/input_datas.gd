class_name InputDatas

var _datas : Array[InputData]

func clear():
	_datas.clear()

func get_touch_count() -> int:
	var count = 0
	for input_data:InputData in _datas:
		if input_data.pressed:
			count += 1
	return count

func get_drag_count() -> int:
	var count = 0
	for input_data:InputData in _datas:
		if input_data.pressed and input_data.draged:
			count += 1
	return count

func get_input_data(index:=0) -> InputData:
	index = max(0, index)
	if index >= _datas.size():
		return null
	return _datas[index]

func get_or_add_input_data(index:=0) -> InputData:
	index = max(0, index)
	if index >= _datas.size():
		_datas.resize(index+1)
	if not _datas[index]:
		var input_data = InputData.new()
		_datas[index] = input_data
	return _datas[index]
