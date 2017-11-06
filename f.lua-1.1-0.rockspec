package = "f.lua"
version = "1.1-0"
source = {
  url = "git://github.com/shakna-israel/f.lua",
  tag = "1.1.0"
}
description = {
  summary = "A functional Lua extension library",
  detailed = [[ A functional Lua extension library,
  bringing the best pieces of Lisp into Lua, to
  enable the writing of programs in a more functional
  style, whilst still remaining Lua.
  ]],
  homepage = "https://github.com/shakna-israel/f.lua",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    f = "f.lua"
  }
}
