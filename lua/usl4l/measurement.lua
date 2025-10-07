--[[
-- Copyright © 2017 Coda Hale (coda.hale@gmail.com)
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

local Measurement = {}
Measurement.__index = Measurement

local function check_value(v)
  if v < 0 then
    error("value must not be negative", 2)
  end
  return v
end

local function new(c, t, l)
  return setmetatable({
    concurrency = check_value(c),
    throughput = check_value(t),
    latency = check_value(l)
  }, Measurement)
end

function Measurement:__tostring()
  return string.format("Measurement[concurrency=%f, throughput=%f, latency=%f]",
    self.concurrency, self.throughput, self.latency)
end

local M = {}

function M.of_concurrency_and_throughput(c, t)
  if t == 0 then
    return new(c, t, 0)
  end
  return new(c, t, c / t)
end

function M.of_concurrency_and_latency(c, l)
  if l == 0 then
    return new(c, 0, l)
  end
  return new(c, c / l, l)
end

function M.of_throughput_and_latency(t, l)
  return new(t * l, t, l)
end

return M