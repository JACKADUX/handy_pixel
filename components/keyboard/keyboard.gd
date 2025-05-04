extends VBoxContainer

signal confirmed(value:float)
signal canceled

@onready var confirm_dialog: PanelContainer = %ConfirmDialog
@onready var label: Label = %Label
@onready var clear: Button = %Clear

@onready var back_space: Button = %BackSpace
@onready var symbols: GridContainer = %Symbols
@onready var dot: Button = %Dot

@onready var button_0: Button = %Button0  
@onready var button_1: Button = %Button1  
@onready var button_2: Button = %Button2  
@onready var button_3: Button = %Button3  
@onready var button_4: Button = %Button4  
@onready var button_5: Button = %Button5  
@onready var button_6: Button = %Button6  
@onready var button_7: Button = %Button7  
@onready var button_8: Button = %Button8  
@onready var button_9: Button = %Button9  

var _value := "0" :
	set(v):
		_value = v
		label.text = v
		
var expression = Expression.new()

var calculate_symbols = ["+","-","*","/"]

func _ready() -> void:
	var number_buttons = [button_0,button_1,button_2,button_3,button_4,button_5,button_6,button_7,button_8,button_9]
	for index:int in number_buttons.size():
		if index == 10:
			break
		var button = number_buttons[index] as Button
		button.pressed.connect(func():
			_on_number_pressed(index)
		)
	for button:Button in symbols.get_children():
		button.pressed.connect(func():
			_on_symbol_pressed(button.get_meta("value"))
		)
	
	dot.pressed.connect(func():
		_add_dot()
	)
	
	back_space.pressed.connect(func():
		_backspace()
	)
	
	clear.pressed.connect(func():
		_value = "0"
	)
	
	confirm_dialog.confirmed.connect(func():
		confirmed.emit(get_value())
	)
	confirm_dialog.canceled.connect(func():
		canceled.emit()
	)
	
func _on_number_pressed(value:int):
	if _value == "0":
		_value = ""
	_value += str(value)

func _add_dot():
	var index = _value.length()
	var has = false
	while index>0:
		index -= 1
		var last = _value[index]
		if last in calculate_symbols:
			break
		if last == ".":
			has = true
			break
	if not has:
		_value += "."
	

func _backspace():
	var v = _value.substr(0, _value.length() -1)
	_value = v if v else "0"

func _on_symbol_pressed(value:String):
	if value == "=":
		get_value()
		return 
	if _value[-1] in calculate_symbols:
		_backspace()
	if _value == "0" and value == "-":
		_value = "-"
		return 
	_value+=value

func get_value() -> float:
	while true:
		# NOTE:从最后开始不是数字的部分全部去掉
		var last = _value[-1]
		if last.is_valid_int():
			break
		_backspace()
	_value =_on_text_submitted(_value)
	return float(_value if _value else 0)
	
func set_value(value:float):
	_value = str(value)

func _on_text_submitted(command):
	var error = expression.parse(command)
	if error != OK:
		print(expression.get_error_text())
		return "0"
	var result = expression.execute()
	if not expression.has_execute_failed():
		return str(result)
	return "0"
