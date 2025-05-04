extends PanelContainer


@onready var goback_button: Button = %GobackButton
@onready var container_agent: ContainerAgent = %ContainerAgent
@onready var margin_container: MarginContainer = %MarginContainer
@onready var edit_button: Button = %EditButton
@onready var import_button: Button = %ImportButton


const ADD_PROJECT_ICON = preload("res://assets/icons/add_96dp_FFFFFF_FILL0_wght400_GRAD0_opsz128.svg")

const Card = preload("res://scenes/project_manage_panel/card/card.gd")
const CARD = preload("res://scenes/project_manage_panel/card/card.tscn")

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
	
	SystemManager.project_system.project_datas_changed.connect(func():
		update_projects()
	)
	
	import_button.pressed.connect(func():
		var files = await ImageUtils.open_image_dialog()
		if not files:
			return
		var file = files.front()
		var image = ImageUtils.create_image_from_file(file, 2048)
		var id = SystemManager.project_system.new_project(Time.get_datetime_string_from_system(),
				image.get_size(),
				SystemManager.project_system.preset_canvas_bg_color
		)
		var image_layers = SystemManager.project_system.load_project_image_layers(id)
		var image_layer = ImageLayer.create_with_image(image)
		image_layers.set_layer(0, image_layer)
		SystemManager.project_system.save_project_image_layers(id, image_layers)
		SystemManager.project_system.set_active_project(id)
		handle_goback()
	)
	
	
	
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
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	card.texture_rect.texture = ADD_PROJECT_ICON
	card.texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	card.texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	card.main_button.pressed.connect(func():
		popup_new_project_panel()
		
	)
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
		var canvas_size = project_data.get("canvas_size", Vector2.ZERO) as Vector2
		if not canvas_size.is_zero_approx():
			card.size_label.text = "%dx%d"%[canvas_size.x,canvas_size.y]
			card.size_label.show()
		else:
			card.size_label.hide()
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
			dialog.confirmed.connect(func():
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
			var image_export_panel = popup_image_export_panel()
			image_export_panel.setup_export(image, file_path)
		)
		
	thread.call_fns(fns)

func handle_goback():
	SystemManager.save_data()
	queue_free()


## Dialogs

const NEW_PROJECT_PANEL = preload("res://scenes/project_manage_panel/new_project_panel/new_project_panel.tscn")
func popup_new_project_panel():
	margin_container.hide()
	var new_project_panel = NEW_PROJECT_PANEL.instantiate()
	var popup_manager = PopupArrowPanelManager.get_from_ui_system()
	var block_layer = popup_manager.custom_popup(new_project_panel)
	
	block_layer.tree_exited.connect(func():
		margin_container.show()
	)
	popup_manager.quick_popup_tween(new_project_panel)
	
	var confirm_dialog = new_project_panel.get_node("%ConfirmDialog")
	confirm_dialog.canceled.connect(func():
		block_layer.queue_free()
	)
	
	confirm_dialog.confirmed.connect(func():
		var id = SystemManager.project_system.new_project(Time.get_datetime_string_from_system(),
				SystemManager.project_system.preset_canvas_size,
				SystemManager.project_system.preset_canvas_bg_color
		)
		SystemManager.project_system.set_active_project(id)
		block_layer.queue_free()
		handle_goback()
	)

const ImageExportPanel = preload("res://scenes/project_manage_panel/image_export_panel/image_export_panel.gd")
const IMAGE_EXPORT_PANEL = preload("res://scenes/project_manage_panel/image_export_panel/image_export_panel.tscn")
func popup_image_export_panel():
	margin_container.hide()
	var image_export_panel = IMAGE_EXPORT_PANEL.instantiate()
	var popup_manager = PopupArrowPanelManager.get_from_ui_system()
	var block_layer = popup_manager.custom_popup(image_export_panel)
	
	block_layer.tree_exited.connect(func():
		margin_container.show()
	)
	popup_manager.quick_popup_tween(image_export_panel)
	
	image_export_panel.confirm_dialog.confirmed.connect(func():
		var pos = size*0.5
		popup_manager.infomation_dialog("图像保存成功!", pos, 1)
		block_layer.queue_free()
	)
	image_export_panel.confirm_dialog.canceled.connect(func():
		block_layer.queue_free()
	)
	
	return image_export_panel
