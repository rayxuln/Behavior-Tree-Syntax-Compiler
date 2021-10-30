tool
extends VBoxContainer


onready var bts_edit = $BTSEdit

onready var edit_menu = $HBoxContainer/EditMenu
onready var file_menu = $HBoxContainer/FileMenu
onready var title_label = $HBoxContainer/TitleLabel

var title = 'Behavior Tree Script Editor'
var current_res:BehaviorTreeScriptResource = null
var has_changed = false

#----- Methods -----
func init(editor:EditorPlugin):
	bts_edit.set_syntax_highlight_color(editor.get_editor_interface())
	bts_edit.text = ''
	current_res = null
	update_title()
	
	file_menu.get_popup().connect('id_pressed', self, '_on_file_menuitem_pressed')
	edit_menu.get_popup().connect('id_pressed', self, '_on_edit_menuitem_pressed')

func edit(res:BehaviorTreeScriptResource):
	current_res = res
	has_changed = false
	update_title()
	
	bts_edit.text = res.data
	bts_edit.clear_undo_history()

func save():
	if not has_changed:
		return
	if current_res == null:
		printerr('You did not open any bts file!')
		return
	
	var err = ResourceSaver.save(current_res.resource_path, current_res)
	if err != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [current_res.resource_path, err])
		return
	
	has_changed = false
	update_title()

func update_title():
	if current_res == null:
		title_label.text = title
	else:
		title_label.text = '%s - %s%s' % [title, current_res.resource_path, ('*' if has_changed else '')]

#----- Signals -----
func _on_BTSEdit_text_changed() -> void:
	has_changed = true
	update_title()
	if current_res:
		current_res.data = bts_edit.text

func _on_file_menuitem_pressed(id:int):
	match id:
		0:
			save()

func _on_edit_menuitem_pressed(id:int):
	match id:
		0:
			bts_edit.undo()
		1:
			bts_edit.redo()
		3:
			bts_edit.copy()
		4:
			bts_edit.cut()
		5:
			bts_edit.paste()
		7:
			bts_edit.select_all()
		8:
			bts_edit.text = ''
		10:
			bts_edit.move_line_up()
		11:
			bts_edit.move_line_down()
		12:
			bts_edit.duplicate_text()
