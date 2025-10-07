#!/bin/bash

set -e

CLI_SCRIPT="./bin/usl4l"
FIXTURES_DIR="./tests/fixtures"
SUCCESS=0
FAILURE=1

# Helper to run a test and check its output
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_output="$3"
    local status=$SUCCESS

    echo "--- Running test: $test_name ---"
    output=$(eval "$command")

    if echo "$output" | grep -qF "$expected_output"; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "  Command: $command"
        echo "  Expected to find: $expected_output"
        echo "  Got: $output"
        status=$FAILURE
    fi
    echo ""
    return $status
}

# --- Test Cases ---

# 1. Test CSV input from file
run_test "CSV input from file" \
    "$CLI_SCRIPT ${FIXTURES_DIR}/cisco.csv" \
    "Max Throughput:  12341.75" || exit $FAILURE

# 2. Test JSON input from file
run_test "JSON input from file" \
    "$CLI_SCRIPT --format json ${FIXTURES_DIR}/cisco.json" \
    "Max Throughput:  12341.75" || exit $FAILURE

# 3. Test CSV input from stdin
run_test "CSV input from stdin" \
    "cat ${FIXTURES_DIR}/cisco.csv | $CLI_SCRIPT" \
    "Max Throughput:  12341.75" || exit $FAILURE

# 4. Test JSON input from stdin
run_test "JSON input from stdin" \
    "cat ${FIXTURES_DIR}/cisco.json | $CLI_SCRIPT --format json" \
    "Max Throughput:  12341.75" || exit $FAILURE

# 5. Test prediction option
run_test "Prediction option" \
    "$CLI_SCRIPT ${FIXTURES_DIR}/cisco.csv --predict 50 --predict 100" \
    "At concurrency 100, expected throughput is 8843.21" || exit $FAILURE

# 6. Test plot option
run_test "Plot option" \
    "$CLI_SCRIPT ${FIXTURES_DIR}/cisco.csv --plot" \
    "plot usl(x) with lines title 'Fitted Model', '-' with points pt 7 title 'Measurements'" || exit $FAILURE

# 7. Test plot option with JSON
run_test "Plot option with JSON" \
    "$CLI_SCRIPT --format json ${FIXTURES_DIR}/cisco.json --plot" \
    "32 12074.39" || exit $FAILURE

# 8. Test for error on not enough data points
echo "--- Running test: Error on insufficient data ---"
if $CLI_SCRIPT <(echo "concurrency,throughput\n1,100\n2,200") >/dev/null 2>&1; then
    echo "FAILED: Expected command to fail but it succeeded."
    exit $FAILURE
else
    echo "PASSED"
fi
echo ""

echo "--- All CLI tests passed! ---"
exit $SUCCESS