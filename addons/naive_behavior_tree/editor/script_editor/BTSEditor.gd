tool
extends VBoxContainer


onready var bts_edit = $BTSEdit

onready var edit_menu = $HBoxContainer/EditMenu
onready var file_menu = $HBoxContainer/FileMenu
onready var title_label = $HBoxContainer/TitleLabel

var title = 'Behavior Tree Script Editor'
var current_source_path:String = ''
var has_changed = false

#----- Methods -----
func init(editor:EditorPlugin):
	bts_edit.set_syntax_highlight_color(editor.get_editor_interface())
	bts_edit.text = ''
	current_source_path = ''
	update_title()
	
	file_menu.get_popup().connect('id_pressed', self, '_on_file_menuitem_pressed')

func edit(source_path:String):
	current_source_path = source_path
	has_changed = false
	update_title()
	
	var err
	var file = File.new()
	err = file.open(source_path, File.READ)
	if err != OK:
		printerr('Can\'t read file: "%s"!' % source_path)
		source_path = ''
		bts_edit.text = ''
		update_title()
		return
	
	bts_edit.text = file.get_as_text()
	

func save():
	if not has_changed:
		return
	
	var err
	var file = File.new()
	err = file.open(current_source_path, File.WRITE)
	if err != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [current_source_path, err])
		return
	
	file.store_string(bts_edit.text)
	
	has_changed = false
	update_title()

func update_title():
	if current_source_path.empty():
		title_label.text = title
	else:
		title_label.text = '%s - %s%s' % [title, current_source_path, ('*' if has_changed else '')]

#----- Signals -----
func _on_BTSEdit_text_changed() -> void:
	has_changed = true
	update_title()

func _on_file_menuitem_pressed(id:int):
	match id:
		0:
			save()
