tool
extends TextEdit

const Tokenizer = preload('../../compiler/Tokenizer.gd')

var builtin_node_name_list := [
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
]

var indent_size := 4

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			$AutoCompletionTimer.stop()
			$AutoCompletionTimer.start()
			if event.alt and event.scancode == KEY_UP:
				move_line_up()
			if event.alt and event.scancode == KEY_DOWN:
				move_line_down()
			if event.control and event.scancode == KEY_D:
				duplicate_text()
	elif event is InputEventMouseButton:
		if event.pressed:
			$CompletionPopup.hide()
	
#----- Methods -----
func set_syntax_highlight_color(editor:EditorInterface):
	add_color_region('"', '"', editor.get_editor_settings().get('text_editor/highlighting/string_color'), false)
	add_color_region("'", "'", editor.get_editor_settings().get('text_editor/highlighting/string_color'), false)
	add_color_region('#', '', editor.get_editor_settings().get('text_editor/highlighting/comment_color'), true)
	
	add_keyword_color('subtree', editor.get_editor_settings().get('text_editor/highlighting/keyword_color'))
	add_keyword_color('tree', editor.get_editor_settings().get('text_editor/highlighting/keyword_color'))
	add_keyword_color('import', editor.get_editor_settings().get('text_editor/highlighting/keyword_color'))
	add_keyword_color('true', editor.get_editor_settings().get('text_editor/highlighting/keyword_color'))
	add_keyword_color('false', editor.get_editor_settings().get('text_editor/highlighting/keyword_color'))
	
	for s in builtin_node_name_list:
		add_keyword_color(s, editor.get_editor_settings().get('text_editor/highlighting/function_color'))
	
	indent_size = editor.get_editor_settings().get('text_editor/indent/size')

func get_current_word():
	if text.empty():
		return ''
	var line := cursor_get_line()
	var column := cursor_get_column()
	
	var line_text := get_line(line)
	var t = Tokenizer.new()
	t.init(line_text)
	
	var res := ''
	while not t.preview_next().type in [Tokenizer.Token.EOF, Tokenizer.Token.ERROR]:
		var token = t.get_next()
		if token.type == Tokenizer.Token.ID:
			if token.start < column and token.start + token.length >= column:
				res = token.value.substr(0, column - token.start)
				break
	
	if res.length() < 2:
		return ''
	return res
	

func get_current_pos(prefix:String):
	if text.empty():
		return Vector2.ZERO
	var line := cursor_get_line()
	var column := cursor_get_column()
	var line_text := get_line(line)
	var font:Font = get_font('font')
	var res = font.get_string_size(line_text.substr(0, column))
	var tab_size = indent_size
	var tab_count = 0
	for s in line_text:
		if s == '\t':
			tab_count += 1
	var tab_x = tab_size * tab_count * font.get_char_size(' '.ord_at(0)).x
	
	var line_number_w = 0
	var line_number = get_line_count()-1
	while line_number:
		line_number_w += 1
		line_number /= 10
	line_number_w = (line_number_w+1) * font.get_char_size('0'.ord_at(0)).x
	
	res.x += tab_x + line_number_w - font.get_string_size(prefix).x - 3 - scroll_horizontal # margin
	res.y = (line+1-scroll_vertical) * get_row_height()
	return res
	
func get_row_height():
	var font:Font = get_font('font')
	var line_spacing = get_constant("line_spacing")
	return font.get_height() + line_spacing

func move_line_up():
	var line = cursor_get_line()
	var max_line = get_line_count()
	var up_line = max(0, line-1)
	
	if up_line == line:
		return
	
	var up_line_text = get_line(up_line)
	var line_text = get_line(line)
	
	set_line(line, up_line_text)
	set_line(up_line, line_text)
	cursor_set_line(up_line)

func move_line_down():
	var line = cursor_get_line()
	var max_line = get_line_count()
	var down_line = min(line+1, max_line-1)
	
	if down_line == line:
		return
	
	var down_line_text = get_line(down_line)
	var line_text = get_line(line)
	
	set_line(line, down_line_text)
	set_line(down_line, line_text)
	cursor_set_line(down_line)

func duplicate_text():
	var line = cursor_get_line()
	var column = cursor_get_column()
	var line_text = get_line(line)
	cursor_set_column(line_text.length())
	insert_text_at_cursor('\n%s' % line_text)
	cursor_set_line(line+1)
	cursor_set_column(column)
#----- Signals -----
func _on_CompletionPopup_completion_selected(prefix:String, word:String) -> void:
	insert_text_at_cursor(word.substr(prefix.length(), word.length() - prefix.length()))


func _on_AutoCompletionTimer_timeout() -> void:
	var prefix = get_current_word()
	$CompletionPopup.rect_position = get_current_pos(prefix)
	$CompletionPopup.build_completion_word_list(prefix, text)
