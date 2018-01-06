# f.lua

A functional Lua extension library.

[![Build Status](https://travis-ci.org/shakna-israel/f.lua.svg?branch=master)](https://travis-ci.org/shakna-israel/f.lua)
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)
 [![Krihelimeter](http://krihelinator.xyz/badge/shakna-israel/f.lua)](http://krihelinator.xyz/repositories/shakna-israel/f.lua) 

Compatibility: Lua 5.1, 5.2, 5.3, and Luajit.

---

## Table of Contents

* [Why?](#why)
* [Install](#install)
* [Usage](#usage)
* [Semantic API](#semantic-api)
* [License](#license)

---

## Why?

f.lua aims to be the most complete functional extension library for Lua, whilst remaining fundamentally Lua.

It's fast, safe, unsurprising and fully-featured, with let statements, string lambdas, and currying. Whether you miss LISP or Haskell whilst working with Lua, this should scratch your itch, without making Lua's VM come to a screeching halt.

---

## Install

You can either copy the f.lua file whever you want it, or install via luarocks:

```
luarocks install f.lua
```

---

## Usage

A brief look:

```
local f = require "f"

f.car(f.cons(2, f.cons(1)))
> 2

f.cdr(f.cons(2, f.cons(1)))
> {1}

f.fn("(x, y) return x, y")(1, 2)
> {1, 2}

f.let({x = 12}, function()
  print(x)
  f.let({x = 24}, function()
    print(x)
  end)
end)
print(x)
> 12
> 24
> nil
```

Refer to the [documentation](https://shakna-israel.github.io/f.lua) for more.

---

## Semantic API

[Semantic versioning](https://semver.org/) is used to guarantee certain things. Whatever you find in the [documentation](https://shakna-israel.github.io/f.lua) is guaranteed.

Any breaking changes will increment the first number.

Any new features will be introduced with an increment to the second number.

Any bug fixes or cosmetic changes will be introduced with an increment to the third number.

---

## License

See [LICENSE](LICENSE).
