# Base class for all ingredients (ABSTRACTION + ENCAPSULATION)
class_name Ingredient
extends RefCounted

# Encapsulated data — accessed through methods, not directly
var _name: String
var _amount: int

func _init(name: String, amount: int = 1) -> void:
	_name = name
	_amount = amount

# Public interface (controlled access to private data)
func get_name() -> String:
	return _name

func get_amount() -> int:
	return _amount

# Overridden by subclasses (POLYMORPHISM)
func get_score_effect() -> int:
	return 0

func is_trap() -> bool:
	return false
