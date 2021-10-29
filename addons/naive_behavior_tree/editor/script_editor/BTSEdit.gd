tool
extends TextEdit

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
