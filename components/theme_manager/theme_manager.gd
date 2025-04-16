@tool
extends ABSThemeManager

const int_4: int = 4
const int_8: int = 8
const int_12: int = 12
const int_16: int = 16
const int_24: int = 24
const int_28: int = 28
const int_32: int = 32
const int_40: int = 40


const size_base    := 48   # x1
const size_small   := 96   # x2
const size_middle  := 144  # x3
const size_large   := 240  # x5

const size_icon = size_small


const color_white := Color("faf4e6")
const color_black := Color("32312D")
const color_yellow := Color("FBC436")
const color_pink := Color("FF54BA")
const color_blue := Color("06B8BA")


# Brand  # 变化时饱和度降低/明度增加 -> 向白色
const color_main := color_yellow
const color_sub := Color("434D1A")
const color_bg_active := Color("434D1A") # 空按钮选中态背景色

# Neutrals  # 变化时饱和度降低/明度增加 -> 向白色
const color_text_primary := color_black
const color_text_subtext := color_black

# Background
const color_bg_base := color_white # 基础背景色
const color_bg_sub := Color("141414") # 次级容器背景色
const color_component_container := Color("171717") # 组件容器背景色
const color_float_container := Color("202122") # 浮层容器背景色
const color_border := color_black # 边框色

# System
const color_amber := Color("#FEB63D")
const color_notice := Color("#51CC56")
const color_warning := Color("#5B93FF")
const color_error := Color("#FF5555")
const color_error_dark := Color("#4D0000")

# Component
var stroke = 6
var corner_radius = stroke*2

var text_size_offset = 0 # 不同字体尺寸会不一样可以根据字体调整
# Titles  # bug？ 24px的字体实际大小是25 多一个像素所以-1
var text_title: int: # onboarding Bold
	get: return 32 + 34 + text_size_offset
var text_sub_title: int: # primary semi-bold
	get: return 24 + 30 + text_size_offset
var text_body: int:
	get: return 16 + 32 + text_size_offset
var text_details: int:
	get: return 14 + 28 + text_size_offset
var text_small: int:
	get: return 10 + 20 + text_size_offset

#
static var contrast: float = 0.2

var font_base = preload("res://assets/fonts/DMSans-Regular.ttf")
var font_bold = preload("res://assets/fonts/DMSans-Medium.ttf")

func _initialize():
	set_font(font_base, text_body)
	
	create_panel_container()
	create_label()
	create_seperator()
	create_button()
	
func create_panel_container():
	var main_panel = PipStyleBoxFlat.new().pip_bg_color(color_bg_base)
	builder.add_type("PanelContainer").panel_set_stylebox(main_panel.get_stylebox_flat())
	
	# base_panel
	var base_panel = (main_panel.pip_duplicate()
		.pip_corner_radius_all(corner_radius)
		.pip_border(color_border, stroke)
		.pip_shadow(color_border, 1, Vector2.ONE*corner_radius)
	)
	builder.add_type("base_panel", "PanelContainer").panel_set_stylebox(base_panel.get_stylebox_flat())

	# popup_panel
	var popup_panel = (base_panel.pip_duplicate()
		.pip_bg_color(color_border)
		.pip_corner_radius_all(corner_radius*2)
		.pip_border_color(color_bg_base)
		.pip_content_margin_all(12)
		.pip_shadow_color(Color(color_border, 0.5))
		.pip_shadow_offset(Vector2.ONE*corner_radius*1.5)
	)
	builder.add_type("popup_panel", "PanelContainer").panel_set_stylebox(popup_panel.get_stylebox_flat())
	
	# clip_panel
	var clip_panel = (main_panel.pip_duplicate()
		.pip_corner_radius_all(corner_radius-stroke)
	)
	builder.add_type("clip_panel", "PanelContainer").panel_set_stylebox(clip_panel.get_stylebox_flat())
	
func create_label():
	(builder.add_type("Label")
		.set_color("font_color", color_text_primary)
	.add_type("label_title", "Label")
		.set_color("font_color", color_text_subtext)
		.set_font("font", font_bold)
		.set_font_size("font_size", text_title) 
	.add_type("label_sub_title", "Label")
		.set_color("font_color", color_text_subtext)
		.set_font_size("font_size", text_sub_title)
	.add_type("label_details", "Label")
		.set_color("font_color", color_text_subtext)
		.set_font_size("font_size", text_details) 
	.add_type("label_small", "Label")
		.set_color("font_color", color_text_subtext)
		.set_font_size("font_size", text_small)
	)

func create_seperator():
	builder.add_type("VSeparator").set_stylebox("separator", StyleBoxEmpty.new())
	builder.add_type("HSeparator").set_stylebox("separator", StyleBoxEmpty.new())
		
	var line = PipStyleBoxFlat.create_stylebox_line(color_border, stroke)
	builder.add_type("seperator_widget_h", "HSeparator").set_stylebox("separator", line)
	
	line = PipStyleBoxFlat.create_stylebox_line(color_border, stroke, true)
	builder.add_type("seperator_widget_v", "VSeparator").set_stylebox("separator", line)
	
func create_button():
	var sc = (PipButtonStyleboxs.create_base_bottons()
		.pip_corner_radius_all(corner_radius)
		.pip_bg_color(color_bg_base)
		.pip_border(color_border, stroke)
		.pip_shadow(color_border, 1, Vector2.ONE*corner_radius)
	)
	
	var cc = (PipButtonColors.create_base_bottons()
		.pip_color_all(color_border)
		.pip_font_color(PipButtonColors.DISABLED, Color(color_border, 0.5))
	)
	
	## base button
	var sc_base_button = (sc.pip_duplicate()
		.pip_content_margin_all((size_middle-size_icon)*0.5)
		.pip_pressed()
			.pip_bg_color(color_main)
			.pip_shadow(color_border, 1, Vector2.ONE*corner_radius*0.5)
			.retrieve_collection()
		.pip_hover()
			.pip_expand_margin_all(6)
			.pip_shadow(Color(color_border, 0.8), 1, Vector2.ONE*corner_radius*1.2)
			.retrieve_collection()
		.pip_disabled()
			.pip_bg_color(Color(color_border, 0.5))
			.pip_border(Color(color_border, 0.8), stroke)
			.pip_shadow(color_border, 0, Vector2.ZERO)
			.retrieve_collection()
	)
	(builder.add_type("base_button", "Button")
		.button_set_stylebox_data(sc_base_button.get_stylebox_flat_data(), true)
		.button_set_colors_data(cc.colors)
		.set_font_size("font_size", text_small)
	)
	
	## tab button
	var sc_tab_button = (sc.pip_duplicate()
		.pip_corner_radius_all(0)
		.pip_border_width_all(0)
		.pip_shadow_size(0)
		.pip_pressed()
			.pip_bg_color(color_main)
			.retrieve_collection()
		.pip_disabled()
			.pip_bg_color(Color(color_border, 0.5))
			.retrieve_collection()
	)
	(builder.add_type("tab_button", "Button")
		.button_set_stylebox_data(sc_tab_button.get_stylebox_flat_data(), true)
		.button_set_colors_data(cc.colors)
	)
	
	
## OLD -----------------
#
#func create_accept_dialog():
	#var base_frame = (MonadStyleBox.create_with_flat().bg_color(color_white)
			#.corner(int_8)
			#.content_margin(int_32)
			#).get_stylebox()
			#
	#(builder.add_type("AcceptDialog")
		#.set_stylebox("panel", base_frame)
		#.set_constant("buttons_min_height", int_32)
		#.set_constant("buttons_min_width", 120)
		#.set_constant("buttons_seperation", int_32)
	#)
#
#func create_popup_menu():
	#var CHECKED 
	##const ALERT_TRIANGLE = preload("res://assets/icons/alert_triangle.png")
	#var base_frame = (MonadStyleBox.create_with_flat().bg_color(color_float_container)
			#.corner(int_8).border(1).border_color(color_border)
			#.content_margin(int_8)
			##.content_margin(int_12, SIDE_TOP)
			##.content_margin(int_12, SIDE_BOTTOM)
			#).get_stylebox()
			#
	#var base_frame_hover = (MonadStyleBox.create_with_flat()
			#.bg_color(color_sub)
			#.corner(6)
			##.content_margin(int_24)
			#).get_stylebox()
			#
	#var line = StyleBoxLine.new()
	#line.color = color_border
	#line.grow_begin = 0
	#line.grow_end = 0
		#
			#
	#(builder.add_type("PopupMenu")
		#.set_stylebox("panel", base_frame)
		#.set_stylebox("hover", base_frame_hover)
		#.set_stylebox("separator", line)
		#.set_icon("checked", CHECKED)
		##.set_icon("submenu", ALERT_TRIANGLE)
		#.set_font_size("font_size", int_16)
		#.set_constant("v_seperation", int_16)
		#.set_constant("item_start_padding", int_16)
		#.set_color("font_hover_color", color_main)
		#.set_color("font_color", color_text_primary)
		#.set_color("font_disabled_color", Color(color_text_subtext, 0.8))
	#)
	## 用在有check的menu上
	#(builder.add_type("popup_menu_no_padding", "PopupMenu")
		#.set_constant("item_start_padding", int_4)
	#)
	#
#func create_popup_panel():
	#var base_frame = (MonadStyleBox.create_with_flat().bg_color(color_float_container)
			#.corner(int_8).border(stroke)
			#.border_color(color_border)
			#.content_margin(int_16)
			##.content_margin(int_8, SIDE_TOP)
			##.content_margin(int_12, SIDE_BOTTOM)
			#).get_stylebox()
	#(builder.add_type("PopupPanel")
		#.set_stylebox("panel", base_frame)
	#)
#
#func create_checkbox():
	#var CHECKBOX_OFF
	#var CHECKBOX_ON
	#
	#var monad_data = MonadStyleBox.with_data(MonadStyleBox.create_with_flat("base").empty()
		#.new_branch_retrave("base", "normal")
		#.new_branch_retrave("base", "pressed")
		#.new_branch_retrave("base", "hover")
		#.new_branch_retrave("base", "disabled")
		#.new_branch_retrave("base", "focus")
		#.new_branch_retrave("base", "hover_pressed")
	#)
	#
	#(builder.add_type("CheckBox")
		#.button_set_stylebox_data(monad_data)
		#.button_set_font_color_all(color_text_primary)
		#.button_set_icon_color_all(color_main)
		#.set_icon("checked", CHECKBOX_ON)
		#.set_icon("unchecked", CHECKBOX_OFF)
		#.set_constant("icon_max_width", int_16)
		#.set_constant("check_v_offset", 1)
	#)
	#
	#var CHECK_BUTTON_OFF
	#var CHECK_BUTTON_ON
	#(builder.add_type("CheckButton")
		#.button_set_stylebox_data(monad_data)
		#.button_set_font_color_all(color_text_primary)
		#.button_set_icon_color_all(color_main)
		#.set_icon("checked", CHECK_BUTTON_ON)
		#.set_icon("unchecked", CHECK_BUTTON_OFF)
		#.set_constant("icon_max_width", int_28)
	#)
#
#func create_line_edit():
	#var base_frame = (MonadStyleBox.create_with_flat().corner(int_8)
			#.bg_color(color_bg_sub).border(1).border_color(color_border)
			#.content_margin_seperate(int_16, -1, int_16, -1)
			#).get_stylebox()
#
	#(builder.add_type("LineEdit")
		#.button_set_font_color_all(color_text_primary)
		#.set_stylebox("focus", base_frame.EMPTY)
		#.set_stylebox("normal", base_frame)
		#.set_font_size("font_size", text_details)
		#.set_color("caret_color", color_text_subtext)
		#.set_color("clear_button_color", color_text_subtext)
		#.set_color("font_placeholder_color", color_text_subtext)
		#.set_color("font_color", color_text_primary)
	#)
#
#func create_option_button():
	#var base_frame = (MonadStyleBox.create_with_flat().corner(int_12)
			#.content_margin_seperate(int_24, int_4, int_24, int_4)
			#).get_stylebox()
			#
	#var monad_data = MonadStyleBox.with_data(MonadStyleBox.new(base_frame, "base")
		#.new_branch_retrave("base", "normal").bg_color(color_bg_base)
		#.new_branch_retrave("base", "pressed").bg_color(color_bg_base)
		#.new_branch_retrave("base", "hover").bg_color(color_main)
		#.new_branch_retrave("base", "disabled").bg_color(color_text_primary)
		#.new_branch_retrave("base", "focus").empty()
	#)
	#(builder.add_type("OptionButton")
		#.button_set_font_color_all(color_text_primary)
		#.button_set_stylebox_data(monad_data)
		#.set_constant("h_separation", int_24)
		#.set_constant("arrow_margin", int_24)
		#.set_font_size("font_size", text_details)
	#)
#
#func create_margin():
	#(builder.add_type("margin_frame", "MarginContainer")
			#.margin_set_side(int_24, SIDE_LEFT)
			#.margin_set_side(int_32, SIDE_TOP)
			#.margin_set_side(int_24, SIDE_RIGHT)
			#.margin_set_side(int_32, SIDE_BOTTOM)
	#)
#
#
## -- 
#
#func create_sidebar():
	## Panel
	#var sidebar_panel = (MonadStyleBox.create_with_flat()
			#.bg_color(color_component_container)
			#.border(1, SIDE_RIGHT)
			#.border_color(color_border)
			#).get_stylebox()
	#builder.add_type("panel_sidebar", "PanelContainer").panel_set_stylebox(sidebar_panel)
	#
	## Button
	#var sidebar_base_frame = (MonadStyleBox.create_with_flat().corner(int_12).border(0)
			#.content_margin_seperate(-1, int_8, -1, int_8)
			#.expand_margin_seperate(int_12, -1, int_12, -1)
			#).get_stylebox()
			#
	#var monad_data = MonadStyleBox.with_data(MonadStyleBox.new(sidebar_base_frame, "base")
		#.new_branch_retrave("base", "normal").draw_center(false)
		#.new_branch_retrave("base", "pressed").bg_color(color_sub)
		#.new_branch_retrave("base", "hover").draw_center(false)
		#.new_branch_retrave("base", "disabled").empty()
		#.new_branch_retrave("base", "focus").empty()
	#)
	#
	#(builder.add_type("btn_sidebar", "Button")
		#.button_set_stylebox_data(monad_data)
		#.button_set_color_all(color_text_primary)
		#.set_constant("h_separation", int_12)
		#.button_set_color("pressed_color", color_main)
		#.button_set_color("hover_color", color_main)
	#)
#
#func create_canvas_inspector():
	#var main_panel = (MonadStyleBox.create_with_flat().bg_color(color_float_container)
			#.border(1).border_color(color_border)
			#.corner(int_8) # .shadow(Color(Color.WHITE, 0.15), 2)
			#.content_margin(int_8)
			#).get_stylebox()
	#(builder.add_type("panel_inspector_canvas", "PanelContainer")
		#.panel_set_stylebox(main_panel)
	#)
	#
	#
	#(builder.add_type("btn_inspector_canvas", "Button")
		#.button_set_color_all(color_text_primary)
		#.set_color("icon_hover_color", color_main)
		#.set_color("icon_disabled_color", offset_color(color_text_subtext, contrast))
	#)
	#
#func create_pmcard_button():
	## Button
	#var sidebar_base_frame = (MonadStyleBox.create_with_flat().corner(int_12).border(0).bg_color(color_component_container)
			#).get_stylebox()
			#
	#var monad_data = MonadStyleBox.with_data(MonadStyleBox.new(sidebar_base_frame, "base")
		#.new_branch_retrave("base", "normal")
		#.new_branch_retrave("base", "pressed").bg_color(color_sub).border(1).border_color(color_main)
		#.new_branch_retrave("base", "hover").border(1).border_color(color_border)
		#.new_branch_retrave("base", "disabled").empty()
		#.new_branch_retrave("base", "focus").empty()
	#)
	#(builder.add_type("btn_pmcard", "Button")
		#.button_set_stylebox_data(monad_data)
	#)
#
#func create_lister_card_button():
	#var sidebar_base_frame = (MonadStyleBox.create_with_flat().corner(int_8).border(0).bg_color(color_component_container)
			#).get_stylebox()
			#
	#var monad_data = MonadStyleBox.with_data(MonadStyleBox.new(sidebar_base_frame, "base")
		#.new_branch_retrave("base", "normal")
		#.new_branch_retrave("base", "pressed").border(1).border_color(color_main)
		#.new_branch_retrave("base", "hover").border(1).border_color(color_border)
		#.new_branch_retrave("base", "disabled").empty()
		#.new_branch_retrave("base", "focus").empty()
	#)
	#(builder.add_type("btn_lister_card", "Button")
		#.button_set_stylebox_data(monad_data)
	#)
#
#func create_property_panel():
	## Panel
	#var panel = (MonadStyleBox.create_with_flat()
			#.corner(int_12)
			#.bg_color(color_bg_sub)
			#.border(1)
			#.border_color(color_border)
			#).get_stylebox()
	#builder.add_type("panel_property", "PanelContainer").panel_set_stylebox(panel)
	#
#func create_custom_overlay_panel():
	#var panel = (MonadStyleBox.create_with_flat()
			#.bg_color(color_float_container).corner(int_12)
			#.border_color(color_border)
			#.border(1).shadow(Color(color_float_container, 0.2), 4, Vector2(2, 2))
			#).get_stylebox()
	#builder.add_type("panel_custom_overlay", "PanelContainer").panel_set_stylebox(panel)
	#
	#var bg_panel = (MonadStyleBox.create_with_flat()
			#.bg_color(color_float_container)
			#).get_stylebox()
	#builder.add_type("panel_overlay_background", "PanelContainer").panel_set_stylebox(bg_panel)
	#
	#bg_panel = (MonadStyleBox.create_with_flat()
			#.bg_color(color_float_container)
			#.content_margin(128)
			#).get_stylebox()
	#builder.add_type("panel_overlay_background_with_margin", "PanelContainer").panel_set_stylebox(bg_panel)
