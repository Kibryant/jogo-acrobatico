# Criteria 10 and 11 of TASK-9: the client's line of text over the game shows one key of GameText
# at a time, translated by its Label (DEC-0031 §8), until it is cleared.
extends GdUnitTestSuite


func test_each_key_shows_until_the_next_one_or_until_cleared() -> void:
	var status: StatusMessage = auto_free(StatusMessage.new())
	add_child(status)
	assert_str(status.shown_key()).is_empty()
	for key: StringName in GameText.KEYS:
		status.show_key(key)
		assert_str(status.shown_key()).is_equal(key)
	status.clear()
	assert_str(status.shown_key()).is_empty()
