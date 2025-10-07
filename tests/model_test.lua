local model = require "usl4l.model"
local measurement = require "usl4l.measurement"

local tests = {}
local EPSILON = 0.0001
local BOOK_TOLERANCE = 0.0002 -- 0.02%

local function assert_close(a, b, tolerance, msg)
  if math.abs(a - b) > tolerance then
    error(string.format("%s: expected %f, got %f", msg, b, a), 2)
  end
end

local function assert_close_percent(a, b, percentage, msg)
    local tolerance = b * percentage
    if math.abs(a - b) > tolerance then
      error(string.format("%s: expected %f (+/-%f%%), got %f", msg, b, percentage*100, a), 2)
    end
end


-- data of Cisco benchmark from Practical Scalability by Baron Schwartz
local CISCO = {
  {1, 955.16}, {2, 1878.91}, {3, 2688.01}, {4, 3548.68}, {5, 4315.54},
  {6, 5130.43}, {7, 5931.37}, {8, 6531.08}, {9, 7219.8}, {10, 7867.61},
  {11, 8278.71}, {12, 8646.7}, {13, 9047.84}, {14, 9426.55}, {15, 9645.37},
  {16, 9897.24}, {17, 10097.6}, {18, 10240.5}, {19, 10532.39}, {20, 10798.52},
  {21, 11151.43}, {22, 11518.63}, {23, 11806}, {24, 12089.37}, {25, 12075.41},
  {26, 12177.29}, {27, 12211.41}, {28, 12158.93}, {29, 12155.27}, {30, 12118.04},
  {31, 12140.4}, {32, 12074.39}
}

-- listed values of the fitted model from the book
local BOOK_KAPPA = 7.690945E-4
local BOOK_SIGMA = 0.02671591
local BOOK_LAMBDA = 995.6486
local BOOK_N_MAX = 35
local BOOK_X_MAX = 12341

local cisco_measurements = {}
for _, d in ipairs(CISCO) do
  table.insert(cisco_measurements, measurement.of_concurrency_and_throughput(d[1], d[2]))
end

local fitted_model = model.build(cisco_measurements)

function tests.test_sigma()
  assert_close_percent(fitted_model.sigma, BOOK_SIGMA, BOOK_TOLERANCE, "sigma")
end

function tests.test_kappa()
  assert_close_percent(fitted_model.kappa, BOOK_KAPPA, BOOK_TOLERANCE, "kappa")
end

function tests.test_lambda()
  assert_close_percent(fitted_model.lambda, BOOK_LAMBDA, BOOK_TOLERANCE, "lambda")
end

function tests.test_max_concurrency()
  assert_close_percent(fitted_model:max_concurrency(), BOOK_N_MAX, BOOK_TOLERANCE, "max_concurrency")
end

function tests.test_max_throughput()
  assert_close_percent(fitted_model:max_throughput(), BOOK_X_MAX, BOOK_TOLERANCE, "max_throughput")
end

function tests.test_coherency()
  if fitted_model:is_coherency_constrained() then
    error("is_coherency_constrained should be false")
  end
end

function tests.test_contention()
  if not fitted_model:is_contention_constrained() then
    error("is_contention_constrained should be true")
  end
end

function tests.test_latency_at_concurrency()
    assert_close(fitted_model:latency_at_concurrency(1), 0.001004398, EPSILON, "latency at N=1")
    assert_close(fitted_model:latency_at_concurrency(20), 0.001807721, EPSILON, "latency at N=20")
    assert_close(fitted_model:latency_at_concurrency(35), 0.002835913, EPSILON, "latency at N=35")
end

function tests.test_throughput_at_concurrency()
    assert_close(fitted_model:throughput_at_concurrency(1), 995.64877, EPSILON, "throughput at N=1")
    assert_close(fitted_model:throughput_at_concurrency(20), 11063.6331, EPSILON, "throughput at N=20")
    assert_close(fitted_model:throughput_at_concurrency(35), 12341.7456, EPSILON, "throughput at N=35")
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