# Must stay clean: the "#" on the second line is text inside the triple-quoted string, and the
# clock call lives only in the real comment after the closing quotes. The lone quote on the first
# line makes a reader that misses the three quotes see that comment as text (TASK-6, criteria 3
# and 6).
var text := """first line with one " quote
# not a comment, still text"""  # Time.get_ticks_msec() lives only in this comment
