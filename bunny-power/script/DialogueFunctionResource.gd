extends DE
class_name DialogueFunction

@export var target_path: NodePath
@export var function_name: String
@export var function_arguments: Array
#already built_in variable within the function we are trying to call
#Ex: if we grab the animation player and call the player function, we would then pass the name of this animation inside of this array. 

@export var hide_dialogue_box: bool
@export var wait_for_signal_to_continue: String = ""
