class_name ImageUtils

const IMAGE_EXTENSION = ["png", "jpg", "jpeg", "webp", "svg"]
const IMAGE_FILETER_EXTENSION = ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.svg"]

#---------------------------------------------------------------------------------------------------
static func image_to_64(value:Image) -> String:
	return Marshalls.raw_to_base64(value.save_png_to_buffer())

#---------------------------------------------------------------------------------------------------
static func image_from_64(value:String) -> Image:
	var image = Image.new()
	image.load_png_from_buffer(Marshalls.base64_to_raw(value))
	return image

#---------------------------------------------------------------------------------------------------
static func resize_image(image:Image, max_size:=1024) -> Image:
	# NOTE: 该方法只会缩小 不会放大
	# 让所有图片的最长边等于max_size，并等比缩放
	var image_size = image.get_size() 
	var aspect :float= image_size.aspect()
	var new_x:float
	var new_y:float
	var small_image :Image = image.duplicate(true)
	if image_size[image_size.max_axis_index()] > max_size:
		if aspect > 1:  # x>y
			new_x = max_size
			new_y = new_x/aspect
		else:
			new_y = max_size
			new_x = new_y*aspect
		small_image.resize(int(new_x), int(new_y))
	return small_image
	
#---------------------------------------------------------------------------------------------------
static func resize_images(images:Array[Image], max_size:=1024) -> Array[Image]:
	# 让所有图片的最长边等于max_size，并等比缩放
	var small_images :Array[Image]= [] 
	for image:Image in images:
		small_images.append(resize_image(image, max_size))
	return small_images

#---------------------------------------------------------------------------------------------------
static func open_image_dialog(muilty_files:=false) -> Array:
	var _dialog_title := "选择图片"
	var files := []
	if not muilty_files:
		files = file_dialog(_dialog_title, [",".join(IMAGE_FILETER_EXTENSION)], DisplayServer.FILE_DIALOG_MODE_OPEN_FILE)
	else:
		files = file_dialog(_dialog_title, [",".join(IMAGE_FILETER_EXTENSION)], DisplayServer.FILE_DIALOG_MODE_OPEN_FILES)
	return files
	
static func get_all_image_path_from(dir_path:String) -> Array:
	var image_paths = []
	for file :String in DirAccess.get_files_at(dir_path):
		if file.get_extension() not in IMAGE_EXTENSION:
			continue
		image_paths.append(dir_path.path_join(file))
	return image_paths

#---------------------------------------------------------------------------------------------------
static func get_image_data_hash(value:Image):
	return str(hash(value.get_data()))

#---------------------------------------------------------------------------------------------------
static func is_same_texture(a:Texture2D, b:Texture2D) -> bool:
	return get_image_data_hash(a.get_image()) == get_image_data_hash(b.get_image())

static func is_same_image(a:Image, b:Image) -> bool:
	return get_image_data_hash(a) == get_image_data_hash(b)

static func create_image_from_file(path:String, max_size:=-1) -> Image:
	var image = Image.load_from_file(path)
	if not image:
		# NOTE: 这里是为了处理一小部分后缀不匹配的图像的
		#		经验上基本只有png和jpg会出现类似问题 所以只处理两种情况
		image = Image.new()
		var buffer = FileAccess.get_file_as_bytes(path)
		var err = OK
		match path.get_extension():
			"png":
				err = image.load_jpg_from_buffer(buffer)
				if err == OK:
					image.save_png(path)
			"jpg":
				err = image.load_png_from_buffer(buffer)
				if err == OK:
					image.save_jpg(path)
		if err != OK:
			return null
		
	if max_size != -1:
		image = resize_image(image, max_size)
	return image

#---------------------------------------------------------------------------------------------------
static func create_texture_from_file(path:String, max_size:=-1) -> Texture2D:
	var image = create_image_from_file(path, max_size)
	if not image:
		return null
	var texture = ImageTexture.create_from_image(image)
	texture.resource_path = path
	texture.resource_name = path.get_file().get_basename()
	return texture

#---------------------------------------------------------------------------------------------------
static func create_texture_from_buffer(byte_array:PackedByteArray, extension:String) -> Texture2D:
	var image = Image.new()
	match extension:
		"png":
			image.load_png_from_buffer(byte_array)
		"jpg","jpeg":
			image.load_jpg_from_buffer(byte_array)
		"webp":
			image.load_webp_from_buffer(byte_array)
		"svg":
			image.load_svg_from_buffer(byte_array)
	var texture = ImageTexture.create_from_image(image)
	return texture

static func file_dialog(title:String="Files", filter=[], mode=DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, current_directory: String="", filename: String="") -> Array:
	var files = []
	var _on_folder_selected = func(status:bool, selected_paths:PackedStringArray, selected_filter_index:int):
		if not status:
			return
		files.append_array(selected_paths)
	DisplayServer.file_dialog_show(title, current_directory, filename,false,
								mode,
								filter,
								_on_folder_selected)
	return files


	
