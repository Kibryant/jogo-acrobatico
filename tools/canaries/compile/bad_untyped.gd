# Must be rejected: an untyped declaration is an error in this project (DEC-0022; TASK-6,
# criteria 4 and 6).


func count_items() -> int:
	var count = 5
	return count
