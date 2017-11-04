# f.lua

A functional Lua extension library.

[![Build Status](https://travis-ci.org/shakna-israel/f.lua.svg?branch=master)](https://travis-ci.org/shakna-israel/f.lua)

---

## Goal

An extension library to make Lua more useful for functional programming, whilst remaining functionally Lua.

---

## Usage

```
f = require "f"

f.car(f.cons(2, f.cons(1)))
> 2

f.cdr(f.cons(2, f.cons(1)))
> {1}

f.fn("(x, y) return x, y")(1, 2)
> {1, 2}
```

I'll write a more detailed API once it stabilises, for now, f.lua is fairly simple and readable.

---

## License

See [LICENSE](LICENSE)
