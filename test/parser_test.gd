extends RaiixTester

var Parser = preload('res://compiler/Parser.gd')
var EXPAST = preload('res://compiler/AST/EXPAST.gd')

var source:String = """
import bark: "res://dog/bt/bark.gd" # 狗叫

# ss
 # sdsd
import run: "res://dog/bt/run.gd"
import dead?: "res://dog/bt/dead_condition.gd"

subtree name: bark_or_run # asd


# e
	# e
	random_selector posibility: 0.5 # 随机选择一个行为

		bark # 叫
		run

subtree name: asda
	asdas sad: 0.3
		saesad
			sadasd
		asd
	asd

tree  #sds+
	
		
	# sd
	(dead?) $bark_or_run # 如果没死的话，就叫或者跑
	 $中文 arg1: sin(	true	) # ee

"""

var source_2:String = """
#
# 小狗的行为树
#

import 叫:"res://dog/bt/BarkTask.gd"
import 摇摆:"res://dog/bt/CareTask.gd"
import 标记:"res://dog/bt/MarkTask.gd"
import 走:"res://dog/bt/WalkTask.gd"

subtree name: 摇摆树
	parallel 										# 并行
		摇摆 次数:  3 							# 摇摆3次
		alwaysFail 								# 总是失败
			'res://dog/bt/RestTask' # 休息

tree
	selector											 # 选择
		$摇摆树 										# 引用子树
		sequence 									# 顺序
			叫 次数: rand_rangei(1, 1)
			走
			"res://dog/bt/BarkTask"	 # 直接使用字符串也行
			标记
	


"""

func get_name():
	return 'Parser Tests'
	
#----- Tests -----
func test_show_tokens():
	var p = Parser.new()
	var t = p.Tokenizer.new()
	t.init(source)
	var token = t.get_next()
	while token.type != p.Tokenizer.Token.EOF:
		print(token)
		token = t.get_next()
	

func _test_should_be_right():
	var p = Parser.new()
	var t = p.Tokenizer.new()
	t.init(source_2)
	p.init(t)
	var ast = p.parse()
	
	print('#----- Import Part -----')
	for i in ast.import_part.import_statement_list:
		print('import %s: %s' % [str(i.id), str(i.path)])
	print('#----- Tree Part -----')
	for subtree in ast.tree_part.subtree_list:
		print('subtree name: %s' % str(subtree.name))
		print(tree_to_string(subtree))
		print('\n')
	print('tree')
	print(tree_to_string(ast.tree_part.tree))
	
	
#----- Methods -----
func prettify_bt(s:String):
	var p = Parser.new()
	var t = p.Tokenizer.new()
	t.init(s)
	p.init(t)
	var ast = p.parse()
	if p.has_error:
		return p.fist_error
	
	var res = ''
	res += ('#----- Import Part -----')
	for i in ast.import_part.import_statement_list:
		res += '\n' + ('import %s: %s' % [str(i.id), str(i.path)])
	res += '\n' + ('#----- Tree Part -----')
	for subtree in ast.tree_part.subtree_list:
		res += '\n' + ('subtree name: %s' % str(subtree.name))
		res += '\n' + (tree_to_string(subtree))
		res += '\n'
	res += '\n' + ('tree')
	res += '\n' + (tree_to_string(ast.tree_part.tree))
	res += '\n'
	return res

func tree_to_string(tree):
	var res = ''
	for tree_node in tree.tree_node_list:
		res += tree_node_to_string(tree_node) + '\n'
	return res

func tree_node_to_string(tree):
	var indent = ''
	for _i in tree.indent.value:
		indent += '\t'
	
	var guard_part = ''
	var cnt = 0
	for t in tree.guard_list:
		guard_part += task_to_string(t)
		if cnt < tree.guard_list.size() - 1:
			guard_part += ', '
		
		cnt += 1
	
	var task = task_to_string(tree.task)
	
	if guard_part.empty():
		return '%s%s' % [indent, task]
	else:
		return '%s(%s) %s' % [indent, guard_part, task]

func task_to_string(task):
	var name = ('$' if task.name.is_subtree_ref else '') + str(task.name.name)
	
	var parameter_part = ''
	var cnt = 0
	for p in task.parameter_list:
		var exp_str = ('%s' if p.exp_node is EXPAST.FuncNode else '(%s)') % exp_to_string(p.exp_node)
		parameter_part += '%s: %s' % [p.id.value, exp_str]
		if cnt < task.parameter_list.size() - 1:
			parameter_part += ' '
		cnt += 1
	
	if parameter_part.empty():
		return name
	else:
		return '%s %s' % [name, parameter_part]

func exp_to_string(exp_node):
	if exp_node is EXPAST.LeafNode:
		return str(exp_node.token.value)
	elif exp_node is EXPAST.OperatorNode:
		var children = exp_node.get('children')
		return '(%s %s %s)' % [exp_to_string(children[0]), exp_node.op.value, exp_to_string(children[1])]
	elif exp_node is EXPAST.FuncNode:
		var arg_part = ''
		var cnt = 0
		for arg in exp_node.children:
			arg_part += exp_to_string(arg)
			if cnt < exp_node.children.size() - 1:
				arg_part += ', '
			cnt += 1
		return '%s(%s)' % [exp_node.id.value, arg_part]
	
