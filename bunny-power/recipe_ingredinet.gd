# A correct ingredient that improves the curry (INHERITANCE)
class_name RecipeIngredient
extends Ingredient

func get_score_effect() -> int:
	return 2

func is_trap() -> bool:
	return false
