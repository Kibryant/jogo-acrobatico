# Must be flagged: the "#" on the second line is inside a triple-quoted string, so the clock call
# after the closing quotes is code. The lone quote on the first line keeps the string open only
# when the three quotes are read as one (TASK-6, criteria 3 and 6).
var text := """first line with one " quote
second # line""" + str(Time.get_ticks_msec())
