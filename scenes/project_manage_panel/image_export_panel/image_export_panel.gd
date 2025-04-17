extends PanelContainer

@onready var scale_buttons = %ScaleButtons
@onready var confirm_dialog: PanelContainer = %ConfirmDialog
@onready var info_label: Label = %InfoLabel
@onready var custom_spin_box_widget: CustomSpinBoxWidget = %CustomSpinBoxWidget
@onready var mul_button: Button = %MulButton


var image:Image
var image_final_size:Vector2
var image_path:String

var _last_value :int= 0

func _ready() -> void:
	for button:Button in scale_buttons.get_children():
		button.pressed.connect(func():
			_set_final_size(button.get_index()+1)
		)
	
	mul_button.pressed.connect(func():
		_set_final_size(custom_spin_box_widget.get_value())
	)
	
	custom_spin_box_widget.value_changed.connect(func(v):
		_set_final_size(custom_spin_box_widget.get_value())
	)
		
	confirm_dialog.confirm_button.pressed.connect(func():
		image.resize(image_final_size.x, image_final_size.y, Image.INTERPOLATE_NEAREST)
		image.save_png(image_path)
		hide()
	)
	confirm_dialog.cancel_button.pressed.connect(func():
		hide()
	)
	
	if not SystemManager.is_initialized():
		await SystemManager.system_initialized
	custom_spin_box_widget.set_value(SystemManager.ui_system.image_export_custom_mul)
	
func show_export(p_image:Image, p_image_path:String):
	image = p_image
	image_path = p_image_path
	if _last_value != 0:
		_set_final_size(_last_value)
	else:
		_set_final_size(1)
	update()
	show()

func _set_final_size(mul:int):
	mul = clamp(mul, 0, INF)
	_last_value = mul
	image_final_size = image.get_size() * mul
	image_final_size = image_final_size.min(Vector2(8192,8192))
	update()

func update():
	info_label.text = "%dx%d"%[image_final_size.x, image_final_size.y]
