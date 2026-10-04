# Must be flagged: in Godot 4.7.2 a quoted string goes on to the next line when the line ends
# inside it, so the "#" there is still text and the clock call after the closing quote is code
# (TASK-6, criteria 3 and 6).
var text := "first line
# still text" + str(Time.get_ticks_msec())
