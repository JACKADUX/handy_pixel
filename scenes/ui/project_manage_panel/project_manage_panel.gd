class_name ProjectManagePanel extends PanelContainer

signal new_project_requested
signal return_canvas_requested

@onready var cancel_button: Button = %CancelButton

@onready var container_agent: ContainerAgent = %ContainerAgent
const ADD_PROJECT_ICON = preload("res://assets/icons/add_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz128.svg")

var thread := ThreadHelper.new()
var _break := false

func _ready() -> void:
	thread.bind_with(self)
	cancel_button.pressed.connect(func():
		return_canvas_requested.emit()
	)
	SystemManager.project_system.project_datas_changed.connect(func():
		update_projects()
	)

func update():
	for card:Card in container_agent.get_items():
		if not card.has_meta("project_id"):
			continue
		if card.get_meta("project_id") != SystemManager.project_system.active_project_id:
			continue
		var image = SystemManager.project_system.get_image_layers_cover(SystemManager.project_system.project_controller.get_image_layers())
		card.texture_rect.texture = ImageTexture.create_from_image(image)

func _add_project_button():
	var card := Card.new_card()
	container_agent.add_item(card)
	card.texture_rect.texture = ADD_PROJECT_ICON
	card.pressed.connect(func():
		new_project_requested.emit()
	)
	card.set_margin(96.0)  # (288-96)*0.5
	ApplyThemeColor.apply(card.texture_rect, "color_black")

func update_projects():
	container_agent.clear()
	_add_project_button()
	var project_datas = SystemManager.project_system.get_project_datas()
	project_datas.reverse()
	var fns = thread.new_fns()
	for project_data in project_datas:
		var card = Card.new_card()
		card.set_meta("project_id", project_data.id)
		container_agent.add_item(card)
		fns.append(func():
			if not project_data.cover_path or not FileAccess.file_exists(project_data.cover_path):
				return 
			var image = Image.load_from_file(project_data.cover_path)
			if not image:
				return 
			card.texture_rect.set_texture.call_deferred(ImageTexture.create_from_image(image))
		)
		card.pressed.connect(func():
			SystemManager.project_system.set_active_project(project_data.id)
			return_canvas_requested.emit()
		)
	thread.call_fns(fns)

	
