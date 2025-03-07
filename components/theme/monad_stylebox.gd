class_name MonadStyleBox

# 通过 monad 的形式创建 stylebox, 可以进行分裂
# 最终目的是 生成对应四个状态的 stylebox

var EMPTY := StyleBoxEmpty.new()

var _parent_monad
var _stylebox:StyleBox
var _unique_names := {}

func _init(stylebox:StyleBox=null, p_unique_name:String="", ):
	if not stylebox:
		stylebox = StyleBoxFlat.new()
	_stylebox = stylebox
	unique_name(p_unique_name)
	
func _to_string():
	return "MonadStyleBox::%s"%str(_stylebox)

func get_stylebox() -> StyleBox:
	return _stylebox

func set_param(property:String, value:Variant) -> MonadStyleBox:
	_stylebox.set(property, value)
	return self

func unique_name(value:String) -> MonadStyleBox:
	if not value:
		return self
	_unique_names[value] = self
	return self

func get_unique(value:String) -> MonadStyleBox:
	# WARNING : 当 value 不存在时 后续连接的方法会正常执行
	#			返回的 monad 对象就是当前对象
	if not _unique_names.has(value):
		push_error("unique_name : '%s' not exists"%value)
		return self
	return _unique_names[value]

func get_root_monad() -> MonadStyleBox:
	var _parent = _parent_monad
	if not _parent:
		return self
	while true:
		if not _parent._parent_monad:
			break
		_parent = _parent._parent_monad
	return _parent

func new_branch(p_unique_name:String="") -> MonadStyleBox:
	var monad = create_with_flat(p_unique_name)
	add_branch_monad(monad)
	return monad

func new_empty_branch(p_unique_name:String="") -> MonadStyleBox:
	var monad = MonadStyleBox.new(EMPTY, p_unique_name)
	add_branch_monad(monad)
	monad.empty()
	return monad

func new_branch_retrave(marked_unique_name:String, p_unique_name:="") -> MonadStyleBox:
	# 会在找到的 unique 对象后面插入新 monad 并返回该 monad
	return get_unique(marked_unique_name).new_branch(p_unique_name)

func add_branch_monad(monad:MonadStyleBox) -> MonadStyleBox:
	# NOTE : get_root_monad 是因为 monad 对象的构建会在 add_child_monad 调用之前
	#			所以需要拿到当前 monad 的根才是正确的
	monad = monad.get_root_monad()
	assert(monad != self , "别胡搞")
	monad._stylebox = _stylebox.duplicate(true)
	_unique_names.merge(monad._unique_names, true) ## 这里字典merge 是为了后续对象拥有覆盖数据的能力
	monad._unique_names = _unique_names  ## 同一个monad链中所有对象都会访问同一个字典
	monad._parent_monad = self
	return self

func empty() -> MonadStyleBox:
	_stylebox = EMPTY
	return self
	
# prop ---
func draw_center(value:=true)-> MonadStyleBox:
	return set_param("draw_center", value)

func bg_color(color_or_hex) -> MonadStyleBox:
	if color_or_hex is String:
		color_or_hex = Color(color_or_hex)
	return set_param("bg_color", color_or_hex)
	
func bg_alpha(value:float) -> MonadStyleBox:
	if _stylebox is StyleBoxFlat:
		_stylebox.bg_color.a = value
	return self

func border_color(color_or_hex) -> MonadStyleBox:
	if color_or_hex is String:
		color_or_hex = Color(color_or_hex)
	return set_param("border_color", color_or_hex)

func border_alpha(value:float) -> MonadStyleBox:
	if _stylebox is StyleBoxFlat:
		_stylebox.border_color.a = value
	return self
	
func corner(value:float, corner_side:int=4) -> MonadStyleBox:
	if _stylebox is StyleBoxFlat:
		match corner_side:
			0: _stylebox.corner_radius_top_left = value
			1: _stylebox.corner_radius_top_right = value
			2: _stylebox.corner_radius_bottom_left = value
			3: _stylebox.corner_radius_bottom_right = value
			_: _stylebox.set_corner_radius_all(value)
	return self
	
func border(value:float, side:int=4) -> MonadStyleBox:
	if _stylebox is StyleBoxFlat:
		match side:
			0: _stylebox.border_width_left = value
			1: _stylebox.border_width_top = value
			2: _stylebox.border_width_right = value
			3: _stylebox.border_width_bottom = value
			_: _stylebox.set_border_width_all(value)
	return self

func expand_margin(value:float, side:int=4)-> MonadStyleBox:
	if _stylebox is StyleBoxFlat or _stylebox is StyleBoxTexture:
		match side:
			0: _stylebox.expand_margin_left = value
			1: _stylebox.expand_margin_top = value
			2: _stylebox.expand_margin_right = value
			3: _stylebox.expand_margin_bottom = value
			_: _stylebox.set_expand_margin_all(value)
	return self

func expand_margin_seperate(left:float, top:float, right:float, bottom:float)-> MonadStyleBox:
	_stylebox.expand_margin_left = left
	_stylebox.expand_margin_top = top
	_stylebox.expand_margin_right = right
	_stylebox.expand_margin_bottom = bottom
	return self
	
func content_margin(value:float, side:int=4)-> MonadStyleBox:
	
	match side:
		0: _stylebox.content_margin_left = value
		1: _stylebox.content_margin_top = value
		2: _stylebox.content_margin_right = value
		3: _stylebox.content_margin_bottom = value
		_: _stylebox.set_content_margin_all(value)
	return self

func content_margin_seperate(left:float, top:float, right:float, bottom:float)-> MonadStyleBox:
	_stylebox.content_margin_left = left
	_stylebox.content_margin_top = top
	_stylebox.content_margin_right = right
	_stylebox.content_margin_bottom = bottom
	return self
	
func shadow(color_or_hex, size:int=0, offset:=Vector2.ZERO)-> MonadStyleBox:
	if color_or_hex is String:
		color_or_hex = Color(color_or_hex)
	if _stylebox is StyleBoxFlat:
		set_param("shadow_color", color_or_hex)
		set_param("shadow_size", size)
		set_param("shadow_offset", offset)
	return self

func get_data() -> Dictionary:
	var data = {}
	for key :String in _unique_names:
		if key.begins_with("_"):
			continue
		data[key] = get_unique(key).get_stylebox()
	return data

static func create_with_flat(p_unique_name:String="") -> MonadStyleBox:
	var stylebox = StyleBoxFlat.new()
	return MonadStyleBox.new(stylebox, p_unique_name)

static func with_data(monad:MonadStyleBox) -> Dictionary:
	return monad.get_root_monad().get_data()
