// Test harness for local CI (see tools/run_tests.sh).
//
// Launch the built game with the environment variable B2B_TEST_MODE=1 set, e.g.:
//     B2B_TEST_MODE=1 Runner.exe -game "MyGame.win" -output test_output.log
//
// GMTL runs its suites at game start as usual. Once they finish, if test mode
// is active the game calls game_end() instead of entering normal gameplay.
// The CI wrapper script then checks the process exit code and parses the
// pass/fail summary from the -output log (which the runner writes itself).
//
// NOTE 1: do NOT read gmtl_coverage_* counters here — GMTL deletes its internal
//         coverage/tests state right after finishing, and reading it afterwards
//         hangs the VM.
// NOTE 2: file writes from the game are sandboxed to the user-data folder in
//         this runner build, so don't rely on writing result files elsewhere.

/// @func	test_mode_active()
/// Returns true if B2B_TEST_MODE=1 is set in the environment.
function test_mode_active() {
	return string(environment_get_variable("B2B_TEST_MODE")) == "1";
}
