#!/usr/bin/env bash
# ============================================================================
# Local CI for Bound to the Bordello
#
# Builds the project with Igor (GameMaker's command-line builder), launches
# the Windows build in test mode (B2B_TEST_MODE=1), lets GMTL run its suites,
# then checks the process exit code and parses the pass/fail summary from the
# -output log. Exits non-zero if anything failed.
#
# Usage:   tools/run_tests.sh          (run from anywhere)
# Exit:    0 = all tests passed
#          1 = tests failed / game crashed before finishing / timed out
#          2 = build failed or environment problem
#
# Requires: Git Bash, GameMaker LTS installed under C:\ProgramData.
# ============================================================================
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YYP="$REPO_ROOT/Bound to the Bordello.yyp"

GM_DATA="/c/ProgramData/GameMakerStudio2-LTS2026"          # runtimes + Igor
GM_USER_ROOT="${APPDATA}/GameMakerStudio2-LTS2026"         # licence / user folder
TEST_TIMEOUT=300                                            # seconds for the game to finish tests

# --- Locate Igor (latest installed runtime) ---------------------------------
# NOTE: Igor's argument parser needs Windows-style (backslash) paths, so all
# values passed to it are converted with cygpath -w below.
RUNTIME="$(ls -d "$GM_DATA"/Cache/runtimes/runtime-* 2>/dev/null | sort -V | tail -1)"
RUNTIME="${RUNTIME%/}"
if [ -z "$RUNTIME" ]; then
    echo "ERROR: no GameMaker runtimes found under $GM_DATA/Cache/runtimes" >&2
    exit 2
fi
IGOR="$RUNTIME/bin/igor/windows/x64/Igor.exe"

# --- Locate the user folder (holds licence info) -----------------------------
USER_DIR=""
for d in "$GM_USER_ROOT"/*/; do
    if [ -f "${d}local_settings.json" ]; then USER_DIR="${d%/}"; break; fi
done
if [ -z "$USER_DIR" ]; then
    echo "ERROR: no GameMaker user folder found under $GM_USER_ROOT" >&2
    exit 2
fi

# Igor wants Windows-style paths.
RUNTIME_WIN="$(cygpath -w "$RUNTIME")"
IGOR_WIN="$(cygpath -w "$IGOR")"
USER_DIR_WIN="$(cygpath -w "$USER_DIR")"
YYP_WIN="$(cygpath -w "$YYP")"

# The .win file is a GameMaker IFF archive, not an executable — it must be
# launched through the runtime's Runner.exe with -game <file.win>.
RUNNER="$RUNTIME/windows/x64/Runner.exe"

BUILD="$REPO_ROOT/.ci/build"
rm -rf "$BUILD"
mkdir -p "$BUILD"

# --- Step 1: compile ----------------------------------------------------------
echo "== Igor: compiling Windows build =="
if ! (cd "$BUILD" && "$IGOR_WIN" \
        /uf="$USER_DIR_WIN" /rp="$RUNTIME_WIN" /project="$YYP_WIN" \
        -- Windows Compile); then
    echo "FAIL: Igor build failed." >&2
    exit 2
fi

EXE="$(find "$BUILD" -name '*.win' | head -1)"
if [ -z "$EXE" ]; then
    echo "FAIL: build produced no .win executable under $BUILD" >&2
    exit 2
fi
echo "== Build OK: $EXE =="

# --- Step 2: run the test suite ------------------------------------------------
# Run from the game directory so -output (a relative filename, written next to
# the executable) lands in a known place.
GAME_DIR="$(dirname "$EXE")"
LOG="$GAME_DIR/test_output.log"
echo "== Running GMTL test suite (timeout ${TEST_TIMEOUT}s) =="
# In test mode the game calls game_end() when GMTL finishes, so Runner exits 0.
# A crash gives a non-zero exit; a hang hits the timeout.
(cd "$GAME_DIR" && B2B_TEST_MODE=1 \
    timeout "$TEST_TIMEOUT" "$RUNNER" -game "$(basename "$EXE")" -output "test_output.log")
RC=$?
if [ "$RC" -eq 124 ]; then
    echo "FAIL: game did not exit within ${TEST_TIMEOUT}s (hung?). See $LOG" >&2
    exit 1
fi
if [ "$RC" -ne 0 ]; then
    echo "FAIL: game exited with code $RC (crash or runtime error). See $LOG" >&2
    if [ -f "$LOG" ]; then tail -n 40 "$LOG"; fi
    exit 1
fi

# --- Step 3: evaluate results ---------------------------------------------------
if ! grep -q "Tests Finished!" "$LOG" 2>/dev/null; then
    echo "FAIL: GMTL never reported 'Tests Finished!' in $LOG." >&2
    exit 1
fi

# GMTL summary lines look like:
#   Test Suites: 2 passed, 3 total. (66.67% success)
#   Tests: 7 passed, 1 failed, 23 skipped, 31 total. (22.58% success)
SUMMARY_TESTS="$(grep -E "^Tests: " "$LOG" | tail -1)"
SUMMARY_SUITES="$(grep -E "^Test Suites: " "$LOG" | tail -1)"
if [ -z "$SUMMARY_TESTS" ]; then
    echo "FAIL: no GMTL summary found in $LOG." >&2
    exit 1
fi

echo "== Results =="
echo "$SUMMARY_SUITES"
echo "$SUMMARY_TESTS"

# Extract "<n> failed" (0 if the segment is absent).
count_failed() {
    echo "$1" | grep -oE '[0-9]+ failed' | grep -oE '^[0-9]+' || true
}
FAILED_TESTS="$(count_failed "$SUMMARY_TESTS")";   FAILED_TESTS=${FAILED_TESTS:-0}
FAILED_SUITES="$(count_failed "$SUMMARY_SUITES")"; FAILED_SUITES=${FAILED_SUITES:-0}

if [ "$FAILED_TESTS" -eq 0 ] && [ "$FAILED_SUITES" -eq 0 ]; then
    echo "== PASS =="
    exit 0
else
    echo "== FAIL: $FAILED_SUITES suite(s), $FAILED_TESTS test(s) failed. Full log: $LOG ==" >&2
    exit 1
fi
