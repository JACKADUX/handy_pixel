extends PanelContainer

signal value_changed(key:String, value:Variant)

@onready var section_panels_v_box_container: VBoxContainer = %SectionPanelsVBoxContainer
@onready var goback_button: Button = %GobackButton

func preprocess_settings(settings:Dictionary):
	var datas = {}
	for key in settings:
		var data = settings[key]
		var pair = data.title.split("/")
		var sections = datas.get_or_add(pair[0], [])
		data.title = pair[1]
		data.key = key
		sections.append(data)
	create_from_data(datas)

func create_from_data(datas:Dictionary):
	for section in datas:
		var section_panel = new_section_panel()
		section_panel.set_title(section)
		for widget_data in datas[section]:
			var control:Control
			match widget_data.get("type", 0):
				TYPE_INT:
					if widget_data.has("select"):
						control = new_selector(section_panel, widget_data.get("title", "unknow_title"), widget_data.get("value"), widget_data.get("select", []), widget_data.get("select_text", []))
					else:	
						control = new_spinbox(section_panel, widget_data.get("title", "unknow_title"), widget_data.get("value"),
								widget_data.get("min_value", 0),widget_data.get("max_value", 100000),widget_data.get("step", 1),widget_data.get("rounded", true),
						)
				TYPE_FLOAT:
					control = new_spinbox(section_panel, widget_data.get("title", "unknow_title"), widget_data.get("value"))
				TYPE_COLOR:
					control = new_color_button(section_panel, widget_data.get("title", "unknow_title"), widget_data.get("value"))
				TYPE_BOOL:
					control = new_check_button(section_panel, widget_data.get("title", "unknow_title"), widget_data.get("value"))
			control.value_changed.connect(func(value):
				value_changed.emit(widget_data.get("key", ""), value)
			)
## Widget

const SettingSectionPanel = preload("uid://bwl5qwvs2dcea")
const SETTING_SECTION_PANEL = preload("uid://7i7nimv7es2f")
func new_section_panel() -> SettingSectionPanel:
	var panel = SETTING_SECTION_PANEL.instantiate()
	section_panels_v_box_container.add_child(panel)
	return panel

const SettingWidget = preload("uid://dut06xq3g0mam")
const SETTING_WIDGET = preload("uid://kthqt8y7x1ok")
func new_widget(title:String, control:Control) -> SettingWidget:
	var widget = SETTING_WIDGET.instantiate()
	widget.set_title.call_deferred(title)
	widget.add_control(control)
	control.custom_minimum_size = Vector2(500, 96)
	return widget

const CUSTOM_SPIN_BOX_WIDGET = preload("uid://by4rjjub5hhuh")
const KeyboardCaller = preload("uid://dti4rg1fgsqck")
func new_spinbox(section_panel:SettingSectionPanel, title:String, value:float=0, min_value:float=1, max_value:float=10000, step:float=1, rounded:=false) -> CustomSpinBoxWidget:
	var control = CUSTOM_SPIN_BOX_WIDGET.instantiate()
	section_panel.add_widget(new_widget(title, control))
	control.min_value = min_value
	control.max_value = max_value
	control.increment = step
	control.rounded = rounded
	control.set_value(value)
	control.add_child(KeyboardCaller.new())
	return control

const ColorSelectionButton = preload("uid://nhy30u51tpg5")
const COLOR_SELECTION_BUTTON = preload("uid://cagu6t0ycb7lu")
func new_color_button(section_panel:SettingSectionPanel, title:String, value:=Color.BLACK) -> ColorSelectionButton:
	var control = COLOR_SELECTION_BUTTON.instantiate()
	section_panel.add_widget(new_widget(title, control))
	control.set_value(value)
	return control

const CustomCheckButton = preload("uid://dtd72xofp2rm4")
const CUSTOM_CHECK_BUTTON = preload("uid://bkjem4vowq8qq")
func new_check_button(section_panel:SettingSectionPanel, title:String, value:=false) -> CustomCheckButton:
	var control = CUSTOM_CHECK_BUTTON.instantiate()
	section_panel.add_widget(new_widget(title, control))
	control.set_value(value)
	return control

const CustomSelector = preload("uid://c5o2tufan6rbo")
const CUSTOM_SELECTOR = preload("uid://bbaua5n045rq6")
func new_selector(section_panel:SettingSectionPanel, title:String, value:Variant, select:=[], select_text:=[]) -> CustomSelector:
	var control = CUSTOM_SELECTOR.instantiate()
	section_panel.add_widget(new_widget(title, control))
	control.init_with(select, select_text)
	control.set_value(value)
	return control
