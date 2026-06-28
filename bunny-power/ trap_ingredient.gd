# A decoy ingredient that ruins the curry (INHERITANCE + POLYMORPHISM)
class_name TrapIngredient
extends Ingredient

func get_score_effect() -> int:
	return -5

func is_trap() -> bool:
	return true
