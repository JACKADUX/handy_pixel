extends Control
# keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
# androiddebugkey
# android

# 安卓图标规范 https://medium.com/google-design/designing-adaptive-icons-515af294c783
func _ready() -> void:
	pass
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if OS.has_feature("android"):
			# NOTE: 理论上应该隐藏系统栏才对 但是不成功
			# TODO: 不会为了这个小需求开发安卓插件吧？？？
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
