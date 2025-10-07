package = "usl4l"
version = "0.1.0-1"
source = {
   url = "git://github.com/marcelog/usl4l"
}
description = {
   summary = "A Lua implementation of the Universal Scalability Law",
   detailed = [[
      usl4l is a Lua implementation of the Universal Scalability Law (USL), a model for quantifying the scalability of a system.
      It provides a library and a command-line interface to analyze performance measurements and predict the scalability of a system.
   ]],
   homepage = "https://github.com/marcelog/usl4l",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "argparse >= 0.6.0",
   "dkjson >= 2.5"
}
build = {
   type = "builtin",
   modules = {
      ["usl4l.model"] = "lua/usl4l/model.lua",
      ["usl4l.parser"] = "lua/usl4l/parser.lua"
   },
   install = {
      bin = { "bin/usl4l" }
   }
}