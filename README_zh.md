# 一个行为树编译器

输入行为树定义脚本，输出PackedScene并保存到项目文件中

## 介绍

本项目行为树节点部分参考 <https://github.com/libgdx/gdx-ai/wiki/Behavior-Trees> 。
编译器部分为自己研发，所以会有很多bug。。。
希望有人能帮忙测试，以便使其能够实际应用。
一下使用`BTS`表示行为树脚本。

## 语法

```
line = [[indent] [guardableTask] [comment]]
guardableTask = [guard [...]] task
guard = '(' task ')'
task = name [param:value [...]] | subtreeRef
```

## 行为树节点

### BTNode

所有行为树节点都继承自此节点

### BehaviorTree

用于存放根节点，可设置`agent`，以便在子节点中获取：`tree.agent`。
可以设置为自己的游戏实体对象。

### BTAction

表示一个动作，自定义节点应该继承自该节点。

示例：

```
tool
extends BTAction

export(String) var msg:String

#----- Methods -----
func execute():
  print(msg)
  return SUCCEEDED
```

需要重载`execute()`函数以便实现自定义功能。
函数中可访问`tree`来得到行为树，`tree.agent`可得到自定义的游戏实体对象。
返回`SUCCEEDED`表示该动作完成了，`FAILED`表示该动作失败了，`RUNNING`表示该动作正在执行。
可以使用`yield`来实现等待信号。

一个使用来`yield`实现的定时器：

```
tool
extends BTAction

export(float) var wait:float = 1

#----- Methods -----
func execute():
  print('wait for 1 sec')
  yield(get_tree().create_timer(wait), "timeout")
  print('wait for 2 sec')
  yield(get_tree().create_timer(2), "timeout")
  print('wait for 3 sec')
  yield(get_tree().create_timer(3), "timeout")
  print('done.')
  return SUCCEEDED

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
 parallel # 并行
  摇摆 次数:  3 # 摇摆3次
  alwaysFail # 总是失败
   res://dog/bt/RestTask' # 休息

tree
 selector  # 选择
  $摇摆树 # 引用子树
  sequence # 顺序
   叫 次数: rand_rangei(1, 1)
   走
   "res://dog/bt/BarkTask" # 直接使用字符串也行
   标记
```
## BTS中的内建节点

```
# Actions
fail # Always fail
success # Always success
timer wait: 1.0 # Wait for 1 sec.

# Composites
dynamic_guard_selector # Choose a child to run at a time by guard check that succeeded.
parallel policy: SEQUENCE/SELECTOR orchestrator: RESUME/JOIN # Run all children at a time with the policy and orchestrator applied.
selector # Choose a child to run in order.
random_selector
sequence # Run children one by one in order.
random_sequence

# Decorators - wrap the result of a child.
always_fail
always_succeed
invert
random success_posibility: 0.5 # Has a chance of 0.5 to run the child.
repeat times: 1 # Repeat the child for 1 time.
until_fail # Run child until it fail.
until_success # Run child until it scceeded.

```

## 许可证

MIT

## 其他

B站地址：https://space.bilibili.com/15155009

爱发电主页：https://afdian.net/@raiix

欢迎赞助支持哟~

蘩的游戏开发交流QQ群：837298758

来分享你刚编的游戏创意或者展现你的游戏开发技术吧~
