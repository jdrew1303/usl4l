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

## Command-Line Interface

`usl4l` now includes a powerful command-line interface (CLI) for quick and easy scalability analysis without needing to write any code.

### Usage

The basic usage is:
```bash
./bin/usl4l [options] [file]
```
The `file` argument is the path to your data file. If not provided, the script will read data from standard input.

### Input Formats

The CLI supports both CSV and JSON input formats.

#### CSV

By default, the tool expects CSV data with two columns: `concurrency` and `throughput`. A header row is expected and will be skipped.

**Example with a CSV file:**
```bash
# Run the model using the sample data
./bin/usl4l tests/fixtures/cisco.csv
```

The output will show the model parameters and peak performance:
```
Model Parameters:
  Sigma (Contention): 0.026716
  Kappa (Crosstalk):  0.000769
  Lambda (Ideal):     995.648786

Peak Performance:
  Max Concurrency: 35
  Max Throughput:  12341.75
```

#### JSON

To use JSON, specify the format with the `-f` or `--format` option. The JSON data can be an array of objects (each with `concurrency` and `throughput` keys) or an array of arrays.

**Example with a JSON file:**
```bash
./bin/usl4l --format json tests/fixtures/cisco.json
```

### Making Predictions

Use the `-p` or `--predict` option to predict throughput at specific concurrency levels. You can use this option multiple times.

**Example:**
```bash
./bin/usl4l --predict 50 --predict 100 tests/fixtures/cisco.csv
```
This will add a "Predictions" section to the output:
```
Predictions:
  At concurrency 50, expected throughput is 11211.53
  At concurrency 100, expected throughput is 8843.21
```

### Visualization with Gnuplot

The `--plot` flag generates a Gnuplot script to visualize the model. You can pipe the output directly to `gnuplot` to display the graph. You may need to install Gnuplot first (`sudo apt-get install gnuplot`).

**Example:**
```bash
./bin/usl4l --plot tests/fixtures/cisco.csv | gnuplot -p
```
This will open a window showing the fitted USL curve along with the original data points.

### Piping Data

The CLI can also read data from `stdin`, which is useful for chaining commands.

**Example:**
```bash
cat tests/fixtures/cisco.csv | ./bin/usl4l
```
Or for JSON:
```bash
cat tests/fixtures/cisco.json | ./bin/usl4l --format json
```

## Library Usage

To use `usl4l` as a library in your own Lua projects, require the `usl4l.measurement` and `usl4l.model` modules.

As an example, consider doing load testing and capacity planning for an HTTP server. To model the
behavior of the system using the [USL][USL], you must first gather a set of measurements of the
system. These measurements must be of two of the three parameters of [Little's Law][LL]: mean
response time (in seconds), throughput (in requests per second), and concurrency (i.e. the number of
concurrent clients).

After your load testing is done, you should have a set of measurements shaped like this:

|concurrency|throughput|
|-----------|----------|
|          1|    955.16|
|          2|   1878.91|
|          ...|   ...|

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

## Attribution

This library is a Lua port of Coda Hale's excellent [usl4j-repo] library. His [blog post on the subject][usl4j-blog] is also a recommended read. The core concepts and the test data are derived from his original work.

## Further reading

I strongly recommend [Practical Scalability Analysis with the Universal Scalability Law][PSA], a
free e-book by [Baron Schwartz][BS], author of [High Performance MySQL][MySQL] and CEO of
[VividCortex][VC]. Trying to use this library without actually understanding the concepts behind
[Little's Law][LL], [Amdahl's Law][AL], and the [Universal Scalability Law][USL] will be difficult
and potentially misleading.

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