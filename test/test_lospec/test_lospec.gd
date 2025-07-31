extends Control

var url = "https://Lospec.com/palette-list"

func _ready() -> void:
	url += "?page=1&number=32&sorting=date"
	return
	var maybe_res = await HttpServer.simple_request(HttpServer.new_http_request_data(url.to_lower(), 5))
	if maybe_res.is_nothing():
		return 
	var html_content = maybe_res.get_value().get("body", []).get_string_from_utf8()
	parse_html(html_content)
	
	
func test():
	#url += "/"+"aspiria-32" + ".json"
	url += ""
	var maybe_res = await HttpServer.simple_request(HttpServer.new_http_request_data(url.to_lower()))
	if maybe_res.is_nothing():
		return 
		
func parse_html(html_content:String):
	#var html_content = maybe_res.get_value().get("body", []).get_string_from_utf8()
	if not html_content:
		return  
	
	 # 2. 创建正则表达式
	var regex = RegEx.new()
	# 匹配模式：<a href="/palette-list/任意非引号字符"
	var err = regex.compile("<a href=\"/palette-list/([^\"]+)\"")
	if err != OK:
		push_error("正则表达式编译失败")
		return
	
	# 3. 查找所有匹配结果
	var results = regex.search_all(html_content)
	var extracted_items = []
	
	# 4. 提取匹配部分
	for result in results:
		if result.get_strings().size() > 1:
			var item = result.get_string(1)  # 获取第一个捕获组
			if item.begins_with("tag/"):
				continue
			extracted_items.append(item)
			print("提取到: ", item)
