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

-- Vendored libraries
package.path = package.path .. ";./lua/vendor/?.lua"
local json = require("dkjson")

-- Core library
local measurement = require("usl4l.measurement")

local M = {}

-- Parses a CSV string into a table of measurements.
-- Expects two columns: concurrency and throughput.
function M.parse_csv(csv_string)
    local measurements = {}
    local lines = {}
    for line in csv_string:gmatch("([^\n\r]+)") do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        if i > 1 then -- Skip header row
            local fields = {}
            for field in line:gmatch('([^,]+)') do
                table.insert(fields, field)
            end

            if #fields == 2 then
                local concurrency = tonumber(fields[1])
                local throughput = tonumber(fields[2])
                if concurrency and throughput then
                    table.insert(measurements, measurement.of_concurrency_and_throughput(concurrency, throughput))
                end
            end
        end
    end
    return measurements
end

-- Parses a JSON string into a table of measurements.
-- Expects an array of objects, each with "concurrency" and "throughput" keys.
function M.parse_json(json_string)
    local ok, data = pcall(json.decode, json_string)
    if not ok then
        error("Failed to parse JSON: " .. tostring(data))
    end

    local measurements = {}
    for _, item in ipairs(data) do
        if item.concurrency and item.throughput then
            local concurrency = tonumber(item.concurrency)
            local throughput = tonumber(item.throughput)
            if concurrency and throughput then
                table.insert(measurements, measurement.of_concurrency_and_throughput(concurrency, throughput))
            end
        else
            -- Also support array of arrays format
            if #item == 2 then
                local concurrency = tonumber(item[1])
                local throughput = tonumber(item[2])
                if concurrency and throughput then
                    table.insert(measurements, measurement.of_concurrency_and_throughput(concurrency, throughput))
                end
            end
        end
    end
    return measurements
end

return M