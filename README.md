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