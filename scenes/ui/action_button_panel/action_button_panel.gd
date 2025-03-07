@tool
class_name ActionButtonPanel extends MarginContainer

@export var mode:=0:
	set(value):
		mode = value
		if is_inside_tree():
			set_mode(mode)
		
@onready var radio_container: RadioContainer = %RadioContainer

@onready var touch_action_button_0: TouchActionButton = $TouchActionButton0
@onready var touch_action_button_1: TouchActionButton = $RadioContainer/TouchActionButton1
@onready var touch_action_button_2: TouchActionButton = $RadioContainer/TouchActionButton2
@onready var touch_action_button_3: TouchActionButton = $RadioContainer/TouchActionButton3
@onready var touch_action_button_4: TouchActionButton = $RadioContainer/TouchActionButton4


@onready var _buttons = [touch_action_button_0, touch_action_button_1, touch_action_button_2, touch_action_button_3, touch_action_button_4]

func _ready() -> void:
	SystemManager.ui_system.action_button_panel = self
	hide()
	set_mode(mode)

func setup_action_buttons(action_button_datas:Array):
	for b in _buttons:
		b.hide()
	for data:Dictionary in action_button_datas:
		var btton:TouchActionButton = _buttons[data.index]
		btton.input_action_requester.action_name = data.action 
		btton.texture_rect.texture = data.icon 
		btton.show()

func set_mode(value:=0):
	match value:
		1: # left
			set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 0)
			radio_container.radius = 280
			radio_container.start_angle = -110
			radio_container.end_angle = 20
			radio_container.center_offset = Vector2(100,140)
		2: # right
			set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 0)
			radio_container.radius = 280
			radio_container.start_angle = 290
			radio_container.end_angle = 160
			radio_container.center_offset = Vector2(140,140)
	
static func create_action_button_data(index:int, action:String, icon:Texture2D) -> Dictionary:
	return {
		"index":index,
		"action":action,
		"icon":icon,
	}
