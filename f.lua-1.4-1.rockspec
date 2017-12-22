package = "f.lua"
version = "1.4-1"
source = {
  url = "git://github.com/shakna-israel/f.lua",
  tag = "1.4.1"
}
description = {
  summary = "The most complete functional library for Lua",
  detailed = [[ f.lua aims to be the most complete functional extension library for Lua, whilst remaining fundamentally Lua.

  It's fast, safe, unsurprising and fully-featured, with let statements, string lambdas, and currying. Whether you miss LISP or Haskell whilst working with Lua, this should scratch your itch, without making Lua's VM come to a screeching halt.
  ]],
  homepage = "https://github.com/shakna-israel/f.lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "none",
  install = {
    lua = {
      "f.lua/f.lua"
    }
  }
}
