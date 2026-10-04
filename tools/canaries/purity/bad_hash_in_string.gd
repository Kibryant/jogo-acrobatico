# Must be flagged: the "#" inside the string must not hide the randi() after it. The old check
# cut every line at its first "#" (TASK-6, criteria 3 and 6).
var label := "#%d" % randi()
