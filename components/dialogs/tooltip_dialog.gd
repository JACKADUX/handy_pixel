extends PanelContainer

@onready var title: Label = %Title
@onready var tooltip: Label = %Tooltip

func set_tooltip(p_title:String, p_tooltip:String):
	if not p_title:
		title.hide()
	else:
		title.show()
	title.text = p_title
	if not p_tooltip:
		tooltip.hide()
	else:
		tooltip.show()
	tooltip.text = p_tooltip
