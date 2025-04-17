extends Control
# keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
# androiddebugkey
# android

# 安卓图标规范 https://medium.com/google-design/designing-adaptive-icons-515af294c783
func _ready() -> void:
	OS.request_permissions()
