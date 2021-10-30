tool
extends ResourceFormatSaver
class_name BehaviorTreeScriptResourceSaver



func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	var res:PoolStringArray
	res.append('bts')
	return res

func recognize(resource: Resource) -> bool:
	return resource is BehaviorTreeScriptResource

func save(path: String, resource: Resource, flags: int) -> int:
	var err
	var file = File.new()
	err = file.open(path, File.WRITE)
	if err != OK:
		printerr('Can\'t write file: "%s"! code: %d.' % [path, err])
		return err
	
	file.store_string(resource.data)
	return OK
