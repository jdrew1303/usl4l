local measurement = require "usl4l.measurement"

local tests = {}
local EPSILON = 0.00001

local function assert_close(a, b, msg)
  if math.abs(a - b) > EPSILON then
    error(string.format("%s: expected %f, got %f", msg, b, a), 2)
  end
end

function tests.test_concurrency()
  local m = measurement.of_concurrency_and_throughput(3, 5)
  assert_close(m.concurrency, 3, "concurrency")
end

function tests.test_throughput()
  local m = measurement.of_concurrency_and_throughput(3, 5)
  assert_close(m.throughput, 5, "throughput")
end

function tests.test_latency()
  local m = measurement.of_concurrency_and_throughput(3, 5)
  assert_close(m.latency, 0.6, "latency")
end

function tests.test_measurements()
  local cl = measurement.of_concurrency_and_latency(3, 0.6)
  assert_close(cl.concurrency, 3, "cl concurrency")
  assert_close(cl.latency, 0.6, "cl latency")
  assert_close(cl.throughput, 5, "cl throughput")

  local ct = measurement.of_concurrency_and_throughput(3, 5)
  assert_close(ct.concurrency, 3, "ct concurrency")
  assert_close(ct.latency, 0.6, "ct latency")
  assert_close(ct.throughput, 5, "ct throughput")

  local tl = measurement.of_throughput_and_latency(5, 0.6)
  assert_close(tl.concurrency, 3, "tl concurrency")
  assert_close(tl.latency, 0.6, "tl latency")
  assert_close(tl.throughput, 5, "tl throughput")
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