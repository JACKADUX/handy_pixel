extends RefCounted

static func set_label_text(control:Label, args:=[], kwargs:={}):
	if not kwargs.has("value"):
		control.text = ""
		return
	control.text = args[0]%kwargs.value

static func set_label_text_color(control:Label, args:=[], kwargs:={}):
	if not kwargs.has("value"):
		control.text = ""
		return
	var color = kwargs.value
	control.text = args[0]%[color.get(args[1])]

static func set_visible_with_value(control:Node, args:=[], kwargs:={}):
	if not kwargs.has("value"):
		return 
	control.visible = bool(kwargs.value == args[0])
