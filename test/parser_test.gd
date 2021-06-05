extends RaiixTester

var Parser = preload('res://compiler/Parser.gd')

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
	t.init(source)
	p.init(t)
	p.parse()


