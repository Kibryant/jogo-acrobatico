# Criterion 9 of TASK-9 and choice 4: the server's room seats two players, each in a slot that
# picks the fighter's spawn point; a third finds it full, and a seat frees when its player leaves.
extends GdUnitTestSuite

const SEATS := 2 # TASK-9, choice 4
const ALICE := 1450222694
const BRUNO := 78230771
const CARLA := 1293826928


func test_two_players_take_the_two_seats_in_order() -> void:
	var room := Room.new(SEATS)
	assert_bool(room.is_full()).is_false()
	assert_array(room.peers()).is_empty()
	assert_int(room.seat(ALICE)).is_equal(0)
	assert_bool(room.is_full()).is_false()
	assert_int(room.seat(BRUNO)).is_equal(1)
	assert_bool(room.is_full()).is_true()
	assert_int(room.slot_of(ALICE)).is_equal(0)
	assert_int(room.slot_of(BRUNO)).is_equal(1)
	assert_array(room.peers()).is_equal([ALICE, BRUNO])


func test_a_third_player_finds_no_seat() -> void:
	var room := Room.new(SEATS)
	room.seat(ALICE)
	room.seat(BRUNO)
	assert_int(room.seat(CARLA)).is_equal(Room.NO_SEAT)
	assert_int(room.slot_of(CARLA)).is_equal(Room.NO_SEAT)
	assert_array(room.peers()).is_equal([ALICE, BRUNO])


# The next player takes the lowest free seat, wherever the one who left sat.
func test_a_player_who_leaves_frees_the_seat_for_the_next_one() -> void:
	var room := Room.new(SEATS)
	room.seat(ALICE)
	room.seat(BRUNO)
	assert_int(room.leave(ALICE)).is_equal(0)
	assert_bool(room.is_full()).is_false()
	assert_int(room.slot_of(ALICE)).is_equal(Room.NO_SEAT)
	assert_int(room.seat(CARLA)).is_equal(0)
	assert_array(room.peers()).is_equal([CARLA, BRUNO])
	room.leave(CARLA)
	room.leave(BRUNO)
	assert_int(room.seat(ALICE)).is_equal(0)


func test_a_player_takes_one_seat_and_leaving_without_one_changes_nothing() -> void:
	var room := Room.new(SEATS)
	room.seat(ALICE)
	assert_int(room.seat(ALICE)).is_equal(Room.NO_SEAT)
	assert_int(room.leave(BRUNO)).is_equal(Room.NO_SEAT)
	assert_int(room.leave(Room.EMPTY)).is_equal(Room.NO_SEAT)
	assert_array(room.peers()).is_equal([ALICE])
