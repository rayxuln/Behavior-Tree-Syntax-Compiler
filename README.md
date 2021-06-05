# 一个行为树编译器

输入行为树定义脚本，输出PackedScene并保存到项目文件中

## 介绍

本项目行为树节点部分参考 <https://github.com/libgdx/gdx-ai/wiki/Behavior-Trees> 。
编译器部分为自己研发，所以会有很多bug。。。
希望有人能帮忙测试，以便使其能够实际应用。

## 语法

```
line = [[indent] [guardableTask] [comment]]
guardableTask = [guard [...]] task
guard = '(' task ')'
task = name [attr:value [...]] | subtreeRef
```

## 示例

```
# 注释
import alias: "path/to/your/custom/behavior/tree/node.gd" # 导入自定义节点
import dead?: "path/to/your/custom/behavior/tree/node.gd" # 导入自定义节点，标识符可以使用问号

subtree name: xxx # 定义子树，第一个节点为根节点，缩进表示节点的父子关系
	parrallel orchestrator: JOIN # 后面为参数，':'左边为参数名，右边为表达式，可包含函数，表达式在编译时执行求值
		alias
		alias

tree # 必须仅包含1个树，第一个节点为根节点，缩进表示父子关系
	sequence
		$xxx # 引用子树
		(dead?) alias # 使用'dead?'作为护卫节点
```

```
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
```

## 许可证

MIT

## 其他

我是Raiix_蘩_，

B站地址：https://space.bilibili.com/15155009

爱发电主页：https://afdian.net/@raiix

欢迎赞助支持哟~

蘩的游戏开发交流QQ群：837298758

来分享你刚编的游戏创意或者展现你的游戏开发技术吧~
