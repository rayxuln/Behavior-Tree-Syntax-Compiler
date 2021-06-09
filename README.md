# A Naive Behavior Tree Plugin

Compile a behavior tree script, and turn it into a PackedScene file which contains a behavior tree.

[简体中文](./README_zh.md)

## Introduction

The code of BTNode part in this project is literally a copy of this project: <https://github.com/libgdx/gdx-ai/wiki/Behavior-Trees>.

The compiler part is designed by myself, so it might have a lot of bugs. XD

More tests need to be done, so that it can actually be used in a real project.

The `BTS` is refer to `Behavior Tree Script`.

## Syntex

```
line = [[indent] [guardableTask] [comment]]
guardableTask = [guard [...]] task
guard = '(' task ')'
task = name [param:value [...]] | subtreeRef
```

## Behavior Tree Nodes

### BTNode

All behavior tree nodes inherit from this node.

### BehaviorTree

It stores the root node, and the `agent` storing your custom game object which can be used in `BTNode` like this: `tree.agent`.

### BTAction

Refer to an action. Your custom node should inherit from this node.

Example:

```
tool
extends BTAction

export(String) var msg:String

#----- Methods -----
func execute():
  print(msg)
  return SUCCEEDED
```

You need to override `execute()` function in order to implement your custom function.

In this function, you can use `tree` to access the Behavior Tree itself, `tree.agent` to access your custom game object.

Return `SUCCEEDED` to indicate the action is done, `FAILED` is fail, `RUNNING` is running.

You can also use `yield` to wait for a signal in this function, which is considered a 'running' status.

An example implemented a timer using `yield`:

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


## More Example

```
# Comment
import alias: "path/to/your/custom/behavior/tree/node.gd" # Import custom node
import dead?: "path/to/your/custom/behavior/tree/node.gd" # Yes, you can use '?' as an ID or alias name.

subtree name: xxx # Define a subtree, the first node is root, use indent to indicate the relation of parent or child node.
 parrallel orchestrator: JOIN # the left of ':' is parameter，the right is an expression that eval at complie time
  alias
  alias

tree # A bts file can only contain at least one tree. Same as the subtree.
 sequence
  $xxx # Refer to a subtree
  (dead?) alias # use 'dead?' as a guard.
```

```
#
# The behavior tree of a dog.
#

import bark:"res://dog/bt/BarkTask.gd"
import care:"res://dog/bt/CareTask.gd"
import mark:"res://dog/bt/MarkTask.gd"
import walk:"res://dog/bt/WalkTask.gd"

subtree name: caretree
 parallel
  care times:  3 
  alwaysFail
   'res://dog/bt/RestTask' # Use a path to a gdscript directly.

tree
 selector 
  $caretree # use '$' to refer to a subtree
  sequence
   bark times: randi_range(1, 3) # use a buit-in function that return a random integer between 1 and 3.
   walk
   "res://dog/bt/BarkTask"
```

## Built-in nodes in BTS

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

## License

MIT
