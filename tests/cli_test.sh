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

run_failing_test() {
    local test_name="$1"
    local command="$2"
    local expected_error="$3"
    local status=$SUCCESS

    echo "--- Running test: $test_name ---"
    output=$(eval "$command" 2>&1)

    if echo "$output" | grep -qF "$expected_error"; then
        echo "PASSED"
    else
        echo "FAILED"
        echo "  Command: $command"
        echo "  Expected to find: $expected_error"
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
run_failing_test "Error on insufficient data" \
    "$CLI_SCRIPT <(echo 'concurrency,throughput\n1,100\n2,200')" \
    "Error: Not enough data points to build a model. Need at least 6." || exit $FAILURE

# 9. Test for malformed CSV
run_failing_test "Error on malformed CSV" \
    "$CLI_SCRIPT ${FIXTURES_DIR}/malformed.csv" \
    "Invalid number of columns at line 2" || exit $FAILURE

# 10. Test for malformed JSON
run_failing_test "Error on malformed JSON" \
    "$CLI_SCRIPT --format json ${FIXTURES_DIR}/malformed.json" \
    "no valid JSON value" || exit $FAILURE

# 11. Test for invalid format argument
run_failing_test "Error on invalid format argument" \
    "$CLI_SCRIPT --format blah ${FIXTURES_DIR}/cisco.csv" \
    "invalid format: blah" || exit $FAILURE

# 12. Test for nonexistent file
run_failing_test "Error on nonexistent file" \
    "$CLI_SCRIPT nonexistent.csv" \
    "Error: Could not open file nonexistent.csv" || exit $FAILURE

echo "--- All CLI tests passed! ---"
exit $SUCCESS