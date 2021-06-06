tool
extends WindowDialog


func _ready() -> void:
	if not Engine.editor_hint:
		popup_centered()

