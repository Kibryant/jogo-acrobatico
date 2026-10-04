# Must be rejected: an unsafe property and method access is an error in this project (DEC-0022;
# TASK-6, criteria 4 and 6).


func speed(body: Object) -> float:
	return body.velocity.length()
