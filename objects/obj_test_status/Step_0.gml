if (gmtl_has_finished) {
	if (test_mode_active()) {
		show_debug_message("Test mode: tests finished, exiting.");
		game_end();
	} else {
		show_debug_message("Testing complete - moving to room Init.");
		room_goto(rm_init);
	}
}
