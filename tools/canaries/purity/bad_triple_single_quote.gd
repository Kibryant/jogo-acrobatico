# Must be flagged: as in bad_triple_quote.gd, with three single quotes. The apostrophe on the
# first line keeps the string open only when the three quotes are read as one (TASK-6, criteria
# 3 and 6).
var text := '''it's the first line
# still text''' + str(Time.get_ticks_msec())
