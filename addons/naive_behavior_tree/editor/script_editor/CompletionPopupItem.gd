tool
extends RichTextLabel

signal clicked
signal doubleclicked

var bg_style:StyleBoxFlat
var word:String

var selected := false setget _on_set_selected
func _on_set_selected(v):
	if selected != v:
		if v:
			bg_style.bg_color.a = 1
		else:
			bg_style.bg_color.a = 0
	selected = v

func _init() -> void:
	fit_content_height = true
	bbcode_enabled = true
	
	bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#515662")
	bg_style.bg_color.a = 0
	var margin = 3
	bg_style.content_margin_top = margin
	bg_style.content_margin_bottom = margin
	bg_style.content_margin_left = margin
	bg_style.content_margin_right = margin
	add_stylebox_override('normal', bg_style)

func set_word(w:String):
	word = w
	bbcode_text = word

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			emit_signal('clicked')
			if event.doubleclick:
				emit_signal('doubleclicked')
				
