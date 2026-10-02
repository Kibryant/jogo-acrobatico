extends GdUnitTestSuite

## TASK-2 probe: fails on purpose so the CI log can show the failing step and why.
## It lives only on the probe branch and is never merged.


func test_probe_fails_on_purpose_to_show_the_ci_log() -> void:
	var sum: int = 1 + 1
	assert_int(sum).is_equal(3)
