tool
extends Reference

#----- Sub Classes -----
class ImportStatement:
	extends Reference
	
	var id
	var path
	
	func _init(i, p) -> void:
		id = i
		path = p
	

class ImportPart:
	extends Reference
	
	var import_statement_list:Array # [ImportStatement]
	
	func _init() -> void:
		import_statement_list = []
	

class Parameter:
	extends Reference
	
	var id # token
	var exp_node # EXP tree node
	
	

class Name:
	extends Reference
	
	var is_subtree_ref:bool
	var name # token
	
	
	

class Task:
	extends Reference
	
	var name:Name
	var parameter_list:Array # [Parameter]
	
	func _init() -> void:
		parameter_list = []
	

class TreeNode:
	extends Reference
	
	var indent # indent token
	var guard_list:Array # [Task]
	var task:Task
	
	func _init() -> void:
		guard_list = []
	

class TreeStatement:
	extends Reference
	
	var is_subtree:bool
	var name # id token only
	
	var tree_node_list:Array # [TreeNode] - flat
	
	func _init() -> void:
		is_subtree = false
		tree_node_list = []
	

class TreePart:
	extends Reference
	
	var subtree_list:Array # [TreeStatement]
	var tree:TreeStatement # only one tree in a file
	
	func _init() -> void:
		subtree_list = []
	
	


#----- Properties -----
var import_part:ImportPart
var tree_part:TreePart






