tool
extends ScrollContainer

signal completion_selected(prefix, word)

const CompletionPopupItem = preload('CompletionPopupItem.gd')
const Tokenizer = preload('../../compiler/Tokenizer.gd')

var keyword_list := [
	'fail',
	'success',
	'timer',

	'dynamic_guard_selector',
	'parallel',
	'selector',
	'random_selector',
	'sequence',
	'random_sequence',

	'always_fail',
	'always_succeed',
	'invert',
	'random',
	'repeat',
	'until_fail',
	'until_success',
	
	'tree',
	'subtree',
	'import',
	
	'true',
	'false',
	
	'policy',
	'SEQUENCE',
	'SELECTOR',
	
	'orchestrator',
	'RESUME',
	'JOIN',
	
	'wait',
	'success_posibility',
	'times',
]

onready var container:VBoxContainer = $VBoxContainer

var current_item_index := -1
var current_prefix := ''

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_ESCAPE:
					hide()
				KEY_ENTER, KEY_TAB:
					var item = get_current_selected_item()
					if item:
						emit_signal('completion_selected', current_prefix, item.word)
					accept_event()
					hide()
				KEY_UP:
					current_item_index -= 1
					if current_item_index < 0:
						current_item_index = 0
					select(current_item_index)
					accept_event()
				KEY_DOWN:
					current_item_index += 1
					if current_item_index >= container.get_child_count():
						current_item_index = container.get_child_count()-1
					select(current_item_index)
					accept_event()

#----- Methods -----
func on_hide():
	release_focus()

func on_show():
	pass

func build_completion_word_list(prefix, source:String):
	clear()
	current_item_index = -1
	
	current_prefix = prefix
	if current_prefix.empty() or source.empty():
		visible = false
		return
	
	var search_list := {}
	
	var t = Tokenizer.new()
	t.init(source)
	while not t.preview_next().type in [Tokenizer.Token.EOF, Tokenizer.Token.ERROR]:
		var token = t.get_next()
		if token.type == Tokenizer.Token.ID:
			search_list[token.value] = true
	
	for k in keyword_list:
		search_list[k] = true
	
	for k in search_list.keys():
		if k != current_prefix and k.begins_with(current_prefix):
			add_guess_word(k)
	
	select(0)
	
	visible = not empty()

func clear():
	var cs = container.get_children().duplicate()
	for c in cs:
		container.remove_child(c)
		c.free()
	

func empty():
	return container.get_child_count() == 0

func add_guess_word(w:String):
	var l = create_label(w)
	var id = container.get_child_count()
	l.connect('clicked', self, '_on_item_clicked', [l, id])
	l.connect('doubleclicked', self, '_on_item_doubleclicked', [l, id])
	container.add_child(l)

func create_label(s:String):
	var l := CompletionPopupItem.new()
	l.set_word(s)
	return l

func select(id:int):
	current_item_index = id
	unselect_all()
	if current_item_index < 0 or current_item_index >= container.get_child_count():
		current_item_index = -1
	else:
		container.get_child(current_item_index).selected = true
	

func unselect_all():
	for c in container.get_children():
		c.selected = false

func get_current_selected_item():
	if current_item_index < 0 or current_item_index >= container.get_child_count():
		return null
	return container.get_child(current_item_index)
#----- Signals -----
func _on_CompletionPopup_visibility_changed() -> void:
	if is_visible_in_tree():
		on_show()
	else:
		on_hide()

func _on_item_clicked(item:CompletionPopupItem, id:int):
	select(id)

func _on_item_doubleclicked(item:CompletionPopupItem, id:int):
	emit_signal('completion_selected', current_prefix, item.word)
	hide()






