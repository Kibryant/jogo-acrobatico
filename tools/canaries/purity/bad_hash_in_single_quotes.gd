# Must be flagged: a single-quoted string ends at its own closing quote, not at the escaped one,
# so its "#" must not hide the randi() after it (TASK-6, criteria 3 and 6).
var label := '\'#%d' % randi()
