extends PanelContainer


@onready var goback_button: Button = %GobackButton
@onready var container_agent: ContainerAgent = %ContainerAgent
@onready var margin_container: MarginContainer = %MarginContainer
@onready var new_project_panel = %NewProjectPanel
@onready var edit_button: Button = %EditButton

@onready var image_export_panel = %ImageExportPanel


const ADD_PROJECT_ICON = preload("res://assets/icons/add_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz128.svg")

const Card = preload("res://components/card/card.gd")
const CARD = preload("res://components/card/card.tscn")

var thread :ThreadHelper

func _ready() -> void:
	thread = ThreadHelper.new()
	thread.bind_with(self)
	goback_button.pressed.connect(func():
		handle_goback()
	)
	
	edit_button.toggled.connect(func(on_toggle:bool):
		_update_project_edit_buttons()
	)
	
	new_project_panel.cancel_pressed.connect(func():
		new_project_panel.hide()
		margin_container.show()
	)
	SystemManager.project_system.project_datas_changed.connect(func():
		update_projects()
	)
	new_project_panel.ok_pressed.connect(func():
		new_project_panel.hide()
		var id = SystemManager.project_system.new_project(Time.get_datetime_string_from_system(),
				SystemManager.project_system.preset_canvas_size,
				SystemManager.project_system.preset_canvas_bg_color
		)
		SystemManager.project_system.set_active_project(id)
		handle_goback()
	)
	
	image_export_panel.confirm_dialog.confirm_button.pressed.connect(func():
		var pos = size*0.5
		PopupArrowPanelManager.get_from_ui_system().infomation_dialog("Image Saved!", pos, 1)
	)
	
	new_project_panel.hide()
	image_export_panel.hide()
	_update_project_edit_buttons.call_deferred()
	
func _update_project_edit_buttons():
	var first = true
	for card :Card in container_agent.get_items():
		if first:
			first = false
			continue
		card.buttons_container.visible = SystemManager.ui_system.projects_edit_state

func _add_project_button():
	var card := CARD.instantiate()
	container_agent.add_item(card)
	card.texture_rect.texture = ADD_PROJECT_ICON
	card.texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	card.texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	card.main_button.pressed.connect(func():
		new_project_panel.show()
		margin_container.hide()
	)
	#card.set_margin(96.0)  # (288-96)*0.5
	ApplyThemeColor.apply(card.texture_rect, "color_black")

func update_projects():
	container_agent.clear()
	_add_project_button()
	var project_datas = SystemManager.project_system.get_project_datas()
	project_datas.reverse()
	var fns = thread.new_fns()
	for project_data in project_datas:
		var card = CARD.instantiate()
		container_agent.add_item(card)
		card.set_meta("project_id", project_data.id)
		card.buttons_container.visible = SystemManager.ui_system.projects_edit_state
		fns.append(func():
			if not project_data.cover_path or not FileAccess.file_exists(project_data.cover_path):
				return 
			var image = Image.load_from_file(project_data.cover_path)
			if not image:
				return 
			card.texture_rect.set_texture.call_deferred(ImageTexture.create_from_image(image))
		)
		card.main_button.pressed.connect(func():
			SystemManager.project_system.set_active_project(project_data.id)
			handle_goback()
		)
		card.delete_button.pressed.connect(func():
			var control = card.delete_button
			var center = control.global_position + control.get_rect().get_center()
			var dialog = PopupArrowPanelManager.get_from_ui_system().confirm_dialog(center+Vector2(0, 96))
			dialog.confirm_button.pressed.connect(func():
				SystemManager.project_system.delete_project(card.get_meta("project_id"))
			)
		)
		card.export_button.pressed.connect(func():
			var image_layers = SystemManager.project_system.load_project_image_layers(card.get_meta("project_id"))
			if not image_layers:
				return 
			
			var image = image_layers.generate_final_image()
			var dir_path := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
			var file_path = dir_path.path_join(TimeUtils.get_time_stemp_for_name()+"_"+UUID.v4()+".png")
			
			DirAccess.make_dir_recursive_absolute(dir_path)
			image_export_panel.show_export(image, file_path)
			
		)
		
	thread.call_fns(fns)

func handle_goback():
	SystemManager.save_data()
	queue_free()
