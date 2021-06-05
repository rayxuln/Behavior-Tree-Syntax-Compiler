extends Reference



#----- Sub Classes -----
class EXPNode:
	extends Reference
	
	func execute(agent):
		pass
	

class BranchNode:
	extends EXPNode
	
	var children:Array # [EXPNode]
	
	func _init() -> void:
		children = []
	

class OperatorNode:
	extends BranchNode
	
	var op # token
	

class FuncNode:
	extends BranchNode
	
	var id # token
	

class LeafNode:
	extends EXPNode
	
	var token
	

#----- Methods -----
static func execute(lib_table:Dictionary, exp_node:EXPNode):
	return 0

