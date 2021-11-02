tool
extends EditorScript

const DictionaryDatabase = preload('./DictionaryDatabase.gd')

func _run() -> void:
	var db = DictionaryDatabase.new()
	
	db.set('a', 1)
	db.set('b', 1)
	db.set('c', {'a': 1})
	db.set('a/c', {'a': 1})
	db.set('d/c', {'a': 1})
	
	print(db.data)
	
	print(db.get('d/c'))
	print(db.get('d/c/a'))
	print(db.get('a'))
	print(db.get('d/a'))
