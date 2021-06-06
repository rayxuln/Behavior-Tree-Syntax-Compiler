tool
extends EditorInspectorPlugin

signal compile_button_pressed(res)
signal clean_button_pressed(res)

#----- Methods -----
func can_handle(object: Object) -> bool:
	if object is BehaviorTreeScriptResource:
		return true
	return false

func parse_begin(object: Object) -> void:
	pass

func parse_category(object: Object, category: String) -> void:
	pass

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	if path == 'source_path':
		var res = object as BehaviorTreeScriptResource
		var b = Button.new()
		b.text = tr('Compile')
		b.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		b.connect('pressed', self, '_on_compile_button_pressed', [res])
		
		var clean_b = Button.new()
		clean_b.text = tr(('Clean'))
		clean_b.size_flags_horizontal = Button.SIZE_EXPAND_FILL
		clean_b.connect('pressed', self, '_on_clean_button_pressed', [res])
		
		var l = Label.new()
		l.text = res.source_path
		l.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = 2
		
		var hb = HBoxContainer.new()
		hb.add_child(l)
		hb.add_child(b)
		hb.add_child(clean_b)
		
		add_custom_control(hb)
		return true
	return false

func parse_end() -> void:
	pass
	

#----- Signals -----
func _on_compile_button_pressed(res):
	emit_signal('compile_button_pressed', res)

func _on_clean_button_pressed(res):
	emit_signal('clean_button_pressed', res)
