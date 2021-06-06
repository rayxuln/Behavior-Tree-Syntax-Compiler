tool
extends Reference



#----- Sub Classes -----
class EXPNode:
	extends Reference
	
	func execute(agent):
		pass
	
	func get_class():
		return 'EXPNode'

class BranchNode:
	extends EXPNode
	
	var children:Array # [EXPNode]
	
	func _init() -> void:
		children = []
	
	func get_class():
		return 'BranchNode'

class OperatorNode:
	extends BranchNode
	
	var op # token
	
	func get_class():
		return 'OperatorNode'

class FuncNode:
	extends BranchNode
	
	var id # token
	
	func get_class():
		return 'FuncNode'

class LeafNode:
	extends EXPNode
	
	var token
	
	func get_class():
		return 'LeafNode'


