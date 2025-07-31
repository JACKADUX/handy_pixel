extends PanelContainer

signal value_changed(value:Variant)

@onready var r_top_button: TextureButton = %RTopButton
@onready var r_bottom_button: TextureButton = %RBottomButton
@onready var label: Label = %Label

var _index :int= -1
var _select := []
var _select_text := []

func _debug():
	init_with([1,2,3,4], ["t","a","b","c"])

func _ready() -> void:
	r_top_button.pressed.connect(func():
		set_index(_index+1)
	)
	r_bottom_button.pressed.connect(func():
		set_index(_index-1)
	)
	#_debug.call_deferred()

func set_value(value:Variant):
	var index = _select.find(value)
	if index == -1:
		return 
	set_index(index)

func get_value():
	if not _select:
		return 
	return _select[_index]

func set_index(value:int):
	if not _select:
		return 
	if _index == value:
		return 
	_index = wrap(value, 0, _select.size())
	label.text = _select_text[_index]
	value_changed.emit(_select[_index])

func init_with(select:Array, select_text:=[]):
	assert(select_text.size()==0 or select.size() == select_text.size())
	_select = select
	if not select_text:
		_select_text = _select.map(func(i): return str(i))
	else:
		_select_text = select_text
	set_index(0)
