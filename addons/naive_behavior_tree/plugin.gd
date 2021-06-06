tool
extends EditorPlugin

var BTSImportPlugin = preload('./import_plugin/bts_import_plugin.gd')
var bts_import_plugin

var InspectorPlugin = preload('./inspector_plugin/inspector_plugin.gd')
var inspector_plugin


var BTSCompiler = preload('./compiler/Compiler.gd')

var clean_confirm_dialog:ConfirmationDialog

func _enter_tree() -> void:
	bts_import_plugin = BTSImportPlugin.new()
	add_import_plugin(bts_import_plugin)
	
	inspector_plugin = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin)
	
	inspector_plugin.connect('compile_button_pressed', self, '_on_compile_button_pressed')
	inspector_plugin.connect('clean_button_pressed', self, '_on_clean_button_pressed')
	
	clean_confirm_dialog = ConfirmationDialog.new()
	get_editor_interface().get_base_control().add_child(clean_confirm_dialog)
	clean_confirm_dialog.connect('confirmed', self, '_confirm_clean_file')

func _exit_tree() -> void:
	remove_import_plugin(bts_import_plugin)
	bts_import_plugin = null
	
	remove_inspector_plugin(inspector_plugin)
	inspector_plugin = null
	
	clean_confirm_dialog.queue_free()

#----- Methods -----
func compile_task_function(path):
	print('Begin to compile bts: "%s"...' % path)
	if compile(path):
		print('Compile bts: "%s" success!' % path)
	else:
		printerr('Compile bts: "%s" fail!' % path)
	
func set_children_owner(p:Node, o:Node):
	for child in p.get_children():
		child.owner = o
		set_children_owner(child, o)
	

func compile(path:String):
	var basename = path.get_basename()
	var ext = 'tscn'
	var output = '%s.%s' % [basename, ext]
	
	var dir = Directory.new()
	var err = dir.open('res://')
	if err != OK:
		printerr('Can\'t open root directory, code: %d' % err)
		return false
		
	if dir.file_exists(output):
		printerr('File: "%s" exists! Please clean before compile.' % output)
		return false
	
	var file = File.new()
	err = file.open(path, File.READ)
	if err != OK:
		printerr('Can\'t open "%s", code: %d' % [path, err])
		return false
	
	var source = file.get_as_text()
	
	var compiler = BTSCompiler.new()
	compiler.init()
	
	var bt = compiler.compile(source)
	if bt == null:
		printerr('Can\'t compile bts: "%s"' % path)
		return false
	set_children_owner(bt, bt)
	
	var ps = PackedScene.new()
	ps.pack(bt)
	
	err = ResourceSaver.save(output, ps)
	if err != OK:
		printerr('Can\'t save the output: "%s", code: %d' % [output, err])
		return false
	return true
	

func clean_file(path):
	var basename = path.get_basename()
	var ext = 'tscn'
	var output = '%s.%s' % [basename, ext]
	
	print('Cleaning file "%s"' % output)
	var dir = Directory.new()
	var err = dir.open('res://')
	if err != OK:
		printerr('Can\'t open root directory, code: %d' % err)
		return
		
	if not dir.file_exists(output):
		printerr('File: "%s" does not exist!' % output)
		return
	
	err = dir.remove(output)
	if err != OK:
		printerr('Can\'t remove file: "%s", code: %d' % [output, err])
		return
	
	print('Clean done.')
#----- Signals -----
func _on_compile_button_pressed(res:BehaviorTreeScriptResource):
	compile_task_function(res.source_path)

func _on_clean_button_pressed(res:BehaviorTreeScriptResource):
	clean_confirm_dialog.dialog_text = 'Are you sure to delete the result of compiling "%s"?\nThese may do some unchangable influences to your project!' % res.source_path
	clean_confirm_dialog.set_meta('path', res.source_path)
	clean_confirm_dialog.popup_centered()

func _confirm_clean_file():
	if clean_confirm_dialog.has_meta('path'):
		clean_file(clean_confirm_dialog.get_meta('path'))
