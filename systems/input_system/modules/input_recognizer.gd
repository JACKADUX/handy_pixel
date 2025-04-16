class_name InputRecognizer

signal event_occurred(event:String, data:Dictionary)

const EVENT_INPUT_HANDLED = "EVENT_INPUT_HANDLED"  # {"input_datas":input_datas}
const EVENT_STATE_CHANGED = "INPUT_EVENT_STATE_CHANGED" # {"state":state}
const EVENT_HOVERED = "EVENT_HOVERED"  # {"relative": finger_1.relative}
const EVENT_PANED = "EVENT_PANED"    # {"relative": finger_1+2.relative}
const EVENT_ZOOMED = "EVENT_ZOOMED"  # {"center":center, "factor": factor}

enum State {NONE, HOVER, PAN, ZOOM}
var state := State.NONE

var input_datas := InputDatas.new()
	
func handle_input(event: InputEvent) -> void:
	pass

func set_state(value:State):
	if state == value:
		return 
	state = value
	send_event(EVENT_STATE_CHANGED, {"state":state})
	
func send_event(event:String, data:={}):
	event_occurred.emit(event, data)
