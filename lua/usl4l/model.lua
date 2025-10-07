--[[
-- Copyright © 2024 James Drew
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--]]

local Model = {}
Model.__index = Model

function Model:__tostring()
  return string.format("Model[sigma=%f, kappa=%f, lambda=%f]",
    self.sigma, self.kappa, self.lambda)
end

function Model:throughput_at_concurrency(n)
  return (self.lambda * n) / (1 + (self.sigma * (n - 1)) + (self.kappa * n * (n - 1)))
end

function Model:latency_at_concurrency(n)
  return (1 + (self.sigma * (n - 1)) + (self.kappa * n * (n - 1))) / self.lambda
end

function Model:max_concurrency()
  return math.floor(math.sqrt((1 - self.sigma) / self.kappa))
end

function Model:max_throughput()
  return self:throughput_at_concurrency(self:max_concurrency())
end

function Model:latency_at_throughput(x)
  return (self.sigma - 1) / (self.sigma * x - self.lambda)
end

function Model:throughput_at_latency(r)
  local a = 2 * self.kappa * (2 * self.lambda * r + self.sigma - 2)
  local b = math.sqrt(self.sigma^2 + self.kappa^2 + a)
  return (b - self.kappa + self.sigma) / (2.0 * self.kappa * r)
end

function Model:concurrency_at_latency(r)
  local a = (2 * self.kappa * ((2 * self.lambda * r) + self.sigma - 2))
  local b = math.sqrt(self.sigma^2 + self.kappa^2 + a)
  return (self.kappa - self.sigma + b) / (2 * self.kappa)
end

function Model:concurrency_at_throughput(x)
  return self:latency_at_throughput(x) * x
end

function Model:is_coherency_constrained()
  return self.sigma < self.kappa
end

function Model:is_contention_constrained()
  return self.sigma > self.kappa
end

function Model:is_limitless()
  return self.kappa == 0
end

local M = {}

function M.new(sigma, kappa, lambda)
  return setmetatable({
    sigma = sigma,
    kappa = kappa,
    lambda = lambda
  }, Model)
end

-- Solves Ax=b for a 3x3 system
local function solve(a, b)
  local det = a[1][1]*a[2][2]*a[3][3] + a[1][2]*a[2][3]*a[3][1] + a[1][3]*a[2][1]*a[3][2] -
              a[1][3]*a[2][2]*a[3][1] - a[1][2]*a[2][1]*a[3][3] - a[1][1]*a[2][3]*a[3][2]

  if det == 0 then return nil end

  local inv_det = 1 / det
  local x = {}
  x[1] = (b[1]*(a[2][2]*a[3][3] - a[2][3]*a[3][2]) - a[1][2]*(b[2]*a[3][3] - a[2][3]*b[3]) + a[1][3]*(b[2]*a[3][2] - a[2][2]*b[3])) * inv_det
  x[2] = (a[1][1]*(b[2]*a[3][3] - a[2][3]*b[3]) - b[1]*(a[2][1]*a[3][3] - a[2][3]*a[3][1]) + a[1][3]*(a[2][1]*b[3] - b[2]*a[3][1])) * inv_det
  x[3] = (a[1][1]*(a[2][2]*b[3] - b[2]*a[3][2]) - a[1][2]*(a[2][1]*b[3] - b[2]*a[3][1]) + b[1]*(a[2][1]*a[3][2] - a[2][2]*a[3][1])) * inv_det

  return x
end

-- Calculates the Jacobian matrix for the USL model
local function jacobian(params, measurements)
  local J = {}
  for i, m in ipairs(measurements) do
    local n = m.concurrency
    local sigma, kappa, lambda = params[1], params[2], params[3]
    local den = 1 + sigma * (n - 1) + kappa * n * (n - 1)

    J[i] = {}
    J[i][1] = -lambda * n * (n - 1) / (den^2) -- d/d(sigma)
    J[i][2] = -lambda * n * n * (n - 1) / (den^2) -- d/d(kappa)
    J[i][3] = n / den -- d/d(lambda)
  end
  return J
end

function M.build(measurements)
  if #measurements < 6 then
    error("Needs at least 6 measurements")
  end

  -- Initial guess for lambda
  local lambda_guess = 0
  for _, m in ipairs(measurements) do
    if m.concurrency > 0 then
      lambda_guess = math.max(lambda_guess, m.throughput / m.concurrency)
    end
  end

  local params = {0.1, 0.01, lambda_guess} -- sigma, kappa, lambda
  local damping = 0.001
  local max_iter = 5000

  for iter = 1, max_iter do
    local model = M.new(params[1], params[2], params[3])

    -- Calculate residuals
    local residuals = {}
    local chi_sq = 0
    for i, m in ipairs(measurements) do
      residuals[i] = m.throughput - model:throughput_at_concurrency(m.concurrency)
      chi_sq = chi_sq + residuals[i]^2
    end

    -- Calculate Jacobian
    local J = jacobian(params, measurements)

    -- Calculate J'J and J'r
    local JtJ = {{0,0,0},{0,0,0},{0,0,0}}
    local Jtr = {0,0,0}
    for i = 1, #measurements do
      for r = 1, 3 do
        Jtr[r] = Jtr[r] + J[i][r] * residuals[i]
        for c = 1, 3 do
          JtJ[r][c] = JtJ[r][c] + J[i][r] * J[i][c]
        end
      end
    end

    -- Main LM step
    local dp
    while true do
      local A = {}
      for r = 1, 3 do
        A[r] = {}
        for c = 1, 3 do
          A[r][c] = JtJ[r][c]
        end
        A[r][r] = A[r][r] + damping * JtJ[r][r]
      end

      dp = solve(A, Jtr)

      if dp then
        local new_params = {params[1] + dp[1], params[2] + dp[2], params[3] + dp[3]}
        local new_model = M.new(new_params[1], new_params[2], new_params[3])

        local new_chi_sq = 0
        for i, m in ipairs(measurements) do
          local r = m.throughput - new_model:throughput_at_concurrency(m.concurrency)
          new_chi_sq = new_chi_sq + r^2
        end

        if new_chi_sq <= chi_sq then
          params = new_params
          damping = damping / 10
          break
        else
          damping = damping * 10
        end
      else
        damping = damping * 10
      end
      if damping > 1e10 then -- escape if damping gets too high
        error("Unable to build a model for these values")
      end
    end

    -- Check for convergence (simple check on parameter change)
    local change = math.sqrt(dp[1]^2 + dp[2]^2 + dp[3]^2)
    if change < 1e-12 then
      return M.new(params[1], params[2], params[3])
    end
  end

  error("Unable to build a model for these values")
end

return M