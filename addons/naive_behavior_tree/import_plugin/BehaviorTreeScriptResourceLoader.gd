tool
extends ResourceFormatLoader
class_name BehaviorTreeScriptResourceLoader

func get_recognized_extensions() -> PoolStringArray:
	var res:PoolStringArray
	res.append('bts')
	return res

func get_resource_type(path: String) -> String:
	return 'Resource'


func handles_type(typename: String) -> bool:
	return typename == 'Resource'

func load(path: String, original_path: String):
	var res = BehaviorTreeScriptResource.new()
	
	var file = File.new()
	var err = file.open(path, File.READ)
	if err != OK:
		printerr('Can\'t open "%s", code: %d' % [path, err])
		return err

	res.data = file.get_as_text()
	return res

