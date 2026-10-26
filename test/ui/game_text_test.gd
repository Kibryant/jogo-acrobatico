# Criterion 10 of TASK-9 and DEC-0031 §8: every text on screen is a key with a message in pt-BR
# and in en from the start, loaded by the Main when the game opens, so project.godot lists no
# translation. A language the game does not have falls back to en.
extends GdUnitTestSuite

const LANGUAGES: Array[String] = ["pt_BR", "en"]

var _locale_before := ""


func before_test() -> void:
	_locale_before = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_locale_before)


func test_every_key_has_a_message_in_pt_br_and_in_en() -> void:
	for locale: String in LANGUAGES:
		assert_bool(GameText.FILES.has(locale)).is_true()
		var translation := GameText.load_language(locale)
		assert_object(translation).is_not_null()
		assert_str(translation.locale).is_equal(locale)
		for key: StringName in GameText.KEYS:
			var message := str(translation.get_message(key))
			var failure := "%s has no %s message" % [key, locale]
			assert_str(message).override_failure_message(failure).is_not_empty()
			assert_str(message).override_failure_message(failure).is_not_equal(String(key))


# TASK-10.2, criterion 3, the other way round: a message the code never shows is a key that was
# renamed or dropped in GameText and left behind in a .po file.
func test_every_message_of_each_language_is_a_key_the_code_shows() -> void:
	for locale: String in LANGUAGES:
		var translation := GameText.load_language(locale)
		var messages := translation.get_message_list()
		assert_int(messages.size()).is_greater(0)
		for message_id: String in messages:
			if message_id.is_empty():
				continue
			var failure := "%s.po has %s, which is not a key of GameText.KEYS" % [
				locale,
				message_id,
			]
			var known := GameText.KEYS.has(StringName(message_id))
			assert_bool(known).override_failure_message(failure).is_true()


# The English file is not a copy of the Portuguese one. A few words are the same in both, as
# "Dash" and "Mouse" on the options screen (TASK-10.9): GameText names each of them, and only
# those may match.
func test_the_two_languages_say_each_message_their_own_way() -> void:
	var portuguese := GameText.load_language("pt_BR")
	var english := GameText.load_language("en")
	# A short list of exceptions, never a way out of the check.
	assert_int(GameText.SAME_IN_BOTH.size() * 4).is_less(GameText.KEYS.size())
	for key: StringName in GameText.KEYS:
		var same := portuguese.get_message(key) == english.get_message(key)
		if GameText.SAME_IN_BOTH.has(key):
			var stale := "%s is in GameText.SAME_IN_BOTH but differs in pt_BR and en" % key
			assert_bool(same).override_failure_message(stale).is_true()
			continue
		var failure := "%s is the same in pt_BR and en" % key
		assert_bool(same).override_failure_message(failure).is_false()


func test_installed_the_text_follows_the_players_language_or_falls_back_to_english() -> void:
	GameText.install()
	for locale: String in LANGUAGES:
		TranslationServer.set_locale(locale)
		var expected := str(GameText.load_language(locale).get_message(GameText.ROOM_FULL))
		assert_str(GameText.text(GameText.ROOM_FULL)).is_equal(expected)
	TranslationServer.set_locale("de")
	var english := str(GameText.load_language("en").get_message(GameText.SERVER_CLOSED))
	assert_str(GameText.text(GameText.SERVER_CLOSED)).is_equal(english)
