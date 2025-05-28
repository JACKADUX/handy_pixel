extends PanelContainer

@onready var cover_bg: TextureRect = %CoverBG
@onready var cover: TextureRect = %Cover

@onready var active_panel: Panel = %ActivePanel
@onready var index_label: Label = %IndexLabel
@onready var visible_button: TextureButton = %VisibleButton
@onready var fake_button: Node = %FakeButton

@onready var opacity_label: Label = %OpacityLabel
@onready var lock_button: TextureButton = %LockButton
