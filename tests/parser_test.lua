-- Set package path to include vendored and project libraries
-- Initialize LuaRocks loader
pcall(require, "luarocks.loader")

-- Set package path to include project libraries
package.path = "./lua/?.lua;" .. package.path

local parser = require("usl4l.parser")

local tests = {}
local EPSILON = 0.0001

local function assert_equal(a, b, msg)
    if a ~= b then
        error(string.format("%s: expected %s, got %s", msg, tostring(b), tostring(a)), 2)
    end
end

local function assert_close(a, b, tolerance, msg)
  if math.abs(a - b) > tolerance then
    error(string.format("%s: expected %f, got %f", msg, b, a), 2)
  end
end

local function read_fixture(filename)
    local f = assert(io.open("tests/fixtures/" .. filename, "r"))
    local content = f:read("*a")
    f:close()
    return content
end

function tests.test_parse_csv()
    local csv_data = read_fixture("cisco.csv")
    local measurements = parser.parse_csv(csv_data)

    assert_equal(#measurements, 32, "CSV parser should find 32 measurements")
    assert_equal(measurements[1].concurrency, 1, "First measurement concurrency should be 1")
    assert_close(measurements[1].throughput, 955.16, EPSILON, "First measurement throughput should be 955.16")
    assert_equal(measurements[32].concurrency, 32, "Last measurement concurrency should be 32")
    assert_close(measurements[32].throughput, 12074.39, EPSILON, "Last measurement throughput should be 12074.39")
end

function tests.test_parse_json()
    local json_data = read_fixture("cisco.json")
    local measurements = parser.parse_json(json_data)

    assert_equal(#measurements, 32, "JSON parser should find 32 measurements")
    assert_equal(measurements[1].concurrency, 1, "First measurement concurrency should be 1")
    assert_close(measurements[1].throughput, 955.16, EPSILON, "First measurement throughput should be 955.16")
    assert_equal(measurements[32].concurrency, 32, "Last measurement concurrency should be 32")
    assert_close(measurements[32].throughput, 12074.39, EPSILON, "Last measurement throughput should be 12074.39")
end

-- Run all tests
for name, func in pairs(tests) do
  local ok, err = pcall(func)
  if ok then
    print(string.format("PASSED: %s", name))
  else
    print(string.format("FAILED: %s\n  %s", name, err))
  end
end