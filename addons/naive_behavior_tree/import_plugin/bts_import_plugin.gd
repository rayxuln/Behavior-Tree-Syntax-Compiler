tool
extends EditorImportPlugin



enum Presets {
	DEFAULT
}


#----- Methods -----
func get_importer_name() -> String:
	return 'raiix.bts.importer'

func get_visible_name() -> String:
	return 'Naive Behavior Tree'

func get_recognized_extensions() -> Array:
	return ['bts']

func get_save_extension() -> String:
	return 'res'

func get_resource_type() -> String:
	return 'Resource'

func get_preset_count() -> int:
	return Presets.size()

func get_preset_name(preset: int) -> String:
	match preset:
		Presets.DEFAULT:
			return 'Default'
		_:
			return 'Unknown'

func get_import_options(preset: int) -> Array:
	match preset:
		Presets.DEFAULT:
			return []
		_:
			return []
		
func get_option_visibility(option: String, options: Dictionary) -> bool:
	return true

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	var res = BehaviorTreeScriptResource.new()
	res.source_path = source_file
	
	var file_name = '%s.%s' % [save_path, get_save_extension()]
	var err = ResourceSaver.save(file_name, res)
	return err
	
	
