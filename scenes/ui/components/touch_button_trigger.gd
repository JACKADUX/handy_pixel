extends BaseTrigger

enum TriggerType {
			NONE, 
			DOWN_AND_UP
			}

@export var trigger_type:TriggerType
	
func connect_trigger():
	match trigger_type:
		TriggerType.DOWN_AND_UP:
			trigger_control.button_down.connect(func():
				raise_trigger({"is_pressed":true})
			)
			trigger_control.button_up.connect(func():
				raise_trigger({"is_pressed":false})
			)
