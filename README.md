# f.lua

A functional Lua extension library.

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

("(x, y) return x, y")(1, 2)
> {1, 2}
```

Two things are exposed when you require f.lua:

* A library of functional... functions.
* A string lambda syntax, for less verbose anonymous functions.

I'll write a more detailed API once it stabilises, for now, f.lua is fairly simple and readable.

---

## License

See [LICENSE](LICENSE)
