# usl4l

usl4l is a Lua modeler for [Dr. Neil Gunther][NJG]'s [Universal Scalability Law][USL] as described by
[Baron Schwartz][BS] in his book [Practical Scalability Analysis with the Universal Scalability
Law][PSA].

Given a handful of measurements of any two [Little's Law][LL] parameters--throughput, latency, and
concurrency--the [USL][USL] allows you to make predictions about any of those parameters' values
given an arbitrary value for any another parameter. For example, given a set of measurements of
concurrency and throughput, the [USL][USL] will allow you to predict what a system's average latency
will look like at a particular throughput, or how many servers you'll need to process requests and
stay under your SLA's latency requirements.

The model coefficients and predictions should be within 0.02% of those listed in the book.

## How to use this

To use `usl4l`, require the `usl4l.measurement` and `usl4l.model` modules.

As an example, consider doing load testing and capacity planning for an HTTP server. To model the
behavior of the system using the [USL][USL], you must first gather a set of measurements of the
system. These measurements must be of two of the three parameters of [Little's Law][LL]: mean
response time (in seconds), throughput (in requests per second), and concurrency (i.e. the number of
concurrent clients).

Because response time tends to be a property of load (i.e. it rises as throughput or concurrency
rises), the dependent variable in your tests should be mean response time. This leaves either
throughput or concurrency as your independent variable, but thanks to [Little's Law][LL] it doesn't
matter which one you use. For the purposes of discussion, let's say you measure throughput as a
function of the number of concurrent clients working at a fixed rate.

After your load testing is done, you should have a set of measurements shaped like this:

|concurrency|throughput|
|-----------|----------|
|          1|    955.16|
|          2|   1878.91|
|          3|   2688.01|
|          4|   3548.68|
|          5|   4315.54|
|          6|   5130.43|
|          7|   5931.37|
|          8|   6531.08|

For simplicity's sake, let's assume you're storing this as a table of tables. Now you can build a model
and begin estimating things:

```lua
local measurement = require "usl4l.measurement"
local model = require "usl4l.model"

local points = {{1, 955.16}, {2, 1878.91}, {3, 2688.01}} -- etc.

-- Map the points to measurements of concurrency and throughput
local measurements = {}
for _, p in ipairs(points) do
  table.insert(measurements, measurement.of_concurrency_and_throughput(p[1], p[2]))
end

-- Build a model from them
local fitted_model = model.build(measurements)

for i = 10, 200, 10 do
  print(string.format("At %d workers, expect %f req/sec", i, fitted_model:throughput_at_concurrency(i)))
end
```

## Example with `wrk2`

[wrk2](https://github.com/giltene/wrk2) is a popular load testing tool that can be used to generate the necessary measurements for `usl4l`.

First, run `wrk2` against your application with varying concurrency levels. For example, to test with 1 to 32 concurrent connections:

```bash
#!/bin/bash

for i in {1..32}; do
  echo "Testing with $i connections..."
  # This example assumes a fixed rate. Adjust -R as needed for your application.
  wrk2 -t1 -c$i -d30s -R2000 http://localhost:8080/api > "results/c$i.txt"
done
```

This script runs `wrk2` for 30 seconds at each concurrency level from 1 to 32 and saves the output to a separate file for each run.

Next, you need to parse the output of `wrk2` to extract the concurrency and throughput for each run. The following Lua script will parse the result files, build a model, and print predictions:

```lua
local measurement = require "usl4l.measurement"
local model = require "usl4l.model"

local measurements = {}

-- Create a directory for results if it doesn't exist
-- (This part would be run before the bash script)
-- os.execute("mkdir -p results")

for i = 1, 32 do
  local concurrency = i
  local filename = string.format("results/c%d.txt", i)
  local f = io.open(filename, "r")

  if f then
    local content = f:read("*a")
    f:close()

    -- Find the throughput from the wrk2 output
    local _, _, throughput = string.find(content, "Requests/sec:%s+(%d+.%d+)")
    if throughput then
      print(string.format("Concurrency: %d, Throughput: %f", concurrency, throughput))
      table.insert(measurements, measurement.of_concurrency_and_throughput(concurrency, tonumber(throughput)))
    else
      print(string.format("Could not find throughput for concurrency %d in %s", i, filename))
    end
  else
    print(string.format("Could not open file %s", filename))
  end
end

if #measurements > 1 then
  -- Build a model from the measurements
  local fitted_model = model.build(measurements)

  print("\n--- Model Results ---")
  print(string.format("Sigma (contention): %f", fitted_model.sigma))
  print(string.format("Kappa (crosstalk): %f", fitted_model.kappa))
  print(string.format("Lambda (throughput at N=1): %f", fitted_model.lambda))
  print(string.format("Max Throughput: %f at %d users", fitted_model:max_throughput(), fitted_model:max_concurrency()))

  print("\n--- Predictions ---")
  for i = 40, 100, 10 do
    print(string.format("At %d workers, expect %f req/sec", i, fitted_model:throughput_at_concurrency(i)))
  end
else
  print("\nNot enough measurements to build a model.")
end
```

This script reads each `wrk2` output file, extracts the throughput, and creates a `usl4l` model. It then prints the model's parameters and some predictions for higher concurrency levels.

## Attribution

This library is a Lua port of Coda Hale's excellent [usl4j-repo] library. His [blog post on the subject][usl4j-blog] is also a recommended read. The core concepts and the test data are derived from his original work.

## Further reading

I strongly recommend [Practical Scalability Analysis with the Universal Scalability Law][PSA], a
free e-book by [Baron Schwartz][BS], author of [High Performance MySQL][MySQL] and CEO of
[VividCortex][VC]. Trying to use this library without actually understanding the concepts behind
[Little's Law][LL], [Amdahl's Law][AL], and the [Universal Scalability Law][USL] will be difficult
and potentially misleading.

## Roadmap

While `usl4l` is currently a functional port of `usl4j`, there are several potential enhancements for the future:

*   **Command-Line Interface (CLI):** A simple CLI for quick modeling without needing to write a script.
*   **Additional Input Formats:** Support for CSV or JSON input to make it easier to work with data from various load testing tools.
*   **Visualization:** Integration with a plotting library to generate graphs of the scalability model.

## License

Copyright © 2024 James Drew

Distributed under the Apache License 2.0.

[NJG]: http://www.perfdynamics.com/Bio/njg.html
[AL]: https://en.wikipedia.org/wiki/Amdahl%27s_law
[LL]: https://en.wikipedia.org/wiki/Little%27s_law
[PSA]: https://www.vividcortex.com/resources/universal-scalability-law/
[USL]: http://www.perfdynamics.com/Manifesto/USLscalability.html
[BS]: https://www.xaprb.com/
[MySQL]: http://shop.oreilly.com/product/0636920022343.do
[VC]: https://www.vividcortex.com/
[usl4j-repo]: https://github.com/codahale/usl4j
[usl4j-blog]: https://codahale.com/usl4j-and-you/