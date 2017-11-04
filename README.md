# f.lua

A functional Lua extension library.

[![Build Status](https://travis-ci.org/shakna-israel/f.lua.svg?branch=master)](https://travis-ci.org/shakna-israel/f.lua)

Compatibility: Lua 5.1, 5.2, 5.3, and Luajit.

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

This API may change without warning, as this project is a work-in-progress.

* ```f.cons(1, table=nil)```. f.cons takes a value, and either a table or nothing, and prepends it. If no table was given, an empty table is created. The table is finally returned.
* ```f.car(table)```. f.car takes a table, and returns the first value.
* ```f.head(table)```. f.head is a simple alias for f.car.
* ```f.cdr(table)```. f.cdr takes a table, and returns all but the first value.
* ```f.rest(table)```. f.rest is a simple alias for c.cdr.
* ```f.elif(predicate, a, b)```. f.elif takes a boolean, and two values. If the boolean is true, for the first value is returned, otherwise the second value is returned.
* ```f.fn("(args) return x")(calls)```. f.fn takes a string with a certain format, and returns a function. The string must begin with "()", which is a sort of alias for Lua's "function()", and should be a valid Lua program.
* ```f.let({x = 12}, function() print(x) end)```. f.let takes a table of values, and a function. It binds the values in place, and then calls the function, before unbinding the variables again. Any variables overridden by let get restored.

---

## License

See [LICENSE](LICENSE).
