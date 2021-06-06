tool
extends RaiixTester

var Tokenizer = preload('res://addons/naive_behavior_tree/compiler/Tokenizer.gd')

func get_name():
	return 'Tokenizer Tests'

#----- Methods -----
func print_next(t):
	var token = t.get_next()
	while token.type == Tokenizer.Token.BLANK:
		token = t.get_next()
	if token.type != Tokenizer.Token.ERROR:
		print(token)
#----- Tests -----
func test_should_be_right():
	var t = Tokenizer.new()
	var source = 'ID123 \'Sing\\\\al String\' "Double String" "th3e\\"3" "\\"t12" 中文 213 2.32 .32 "中文" \n  \n\n trueID123 #注释\n\t123 true false :: 123: 666'
	t.init(source)
	while not t.preview_next().type in [Tokenizer.Token.EOF, Tokenizer.Token.ERROR]:
		print_next(t)
	

func _test_should_be_right2():
	var t = Tokenizer.new()
	var source = 'true)'
	t.init(source)
	while not t.preview_next().type in [Tokenizer.Token.EOF, Tokenizer.Token.ERROR]:
		print_next(t)

func test_wrong_number():
	var t = Tokenizer.new()
	var source = '123. .'
	t.init(source)
	print_next(t)
	print_next(t)

func test_wrong_String1():
	var t = Tokenizer.new()
	var source = '"'
	t.init(source)
	print_next(t)
	print_next(t)

func test_wrong_String2():
	var t = Tokenizer.new()
	var source = '123"'
	t.init(source)
	print_next(t)
	print_next(t)

func test_wrong_String3():
	var t = Tokenizer.new()
	var source = "'\\'"
	t.init(source)
	print_next(t)
	print_next(t)

func test_wrong_String4():
	var t = Tokenizer.new()
	var source = '"\\a"'
	t.init(source)
	print_next(t)
	print_next(t)

