# Must be flagged: core/ never reads the wall clock (DEC-0004 rule 1; TASK-6, criterion 6).
var t := Time.get_ticks_msec()
