# f.lua

A functional Lua extension library.

[![Build Status](https://travis-ci.org/shakna-israel/f.lua.svg?branch=master)](https://travis-ci.org/shakna-israel/f.lua)

Compatibility: Lua 5.1, 5.2, 5.3, and Luajit.

---

## Goal

An extension library to make Lua more useful for functional programming, whilst remaining functionally Lua.

---

## Install

You can either copy the f.lua file whever you want it, or install via luarocks:

```
luarocks install f.lua
```

Be aware that the API is still unstable and may change.

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

---

This API may change without warning, as this project is a work-in-progress.

However, I have tried to opt for "least surprising behaviour" for as much as I can. If you find something to behave differently than you expect, please open an issue so we can discuss how best to handle it.

### ```f.cons(1, table=nil)```

f.cons takes a value, and either a table or nothing, and prepends it. If no table was given, an empty table is created. The table is finally returned.

Example:

```
f.cons(1, {2, 3, 4})
> {1, 2, 3, 4}

f.cons(1)
> {1}
```

### ```f.car(table)```

f.car takes a table, and returns the first value.
If the table given is an array, the first value is returned.
If the table given is not an array, a table containing the key and value of the first item is returned.
If the table is empty, nil is returned.

Example:

```
f.car({1, 2, 3})
> 1
f.car({})
> nil
f.car({x = 12, y = 4})
> {x = 12}
```

### ```f.head(table)```

f.head is a simple alias for f.car.

### ```f.cdr(table)```

f.cdr takes a table, and returns all but the first value.
If the table is empty, and empty table is returned.
If the table only had one value, and empty table is returned.
If the table is an array, a table of values is returned.
If the table was not an array, a table of key-value pairs is returned.

Example:

```
f.cdr({1, 2, 3})
> {2, 3}
f.cdr({x = 1, y = 4})
> {y = 4}
f.cdr({})
> {}
```

### ```f.rest(table)```

f.rest is a simple alias for c.cdr.

### ```f.elif(predicate, a, b)```

f.elif takes a boolean, and two values. If the boolean is true, for the first value is returned, otherwise the second value is returned.

Example:

```
f.elif(1 < 2, "Insane", "Sane")
> "Sane"
```

### ```f.fn("(args) return x")(calls)```

f.fn takes a string with a certain format, and returns a function. The string must begin with "()", which is a sort of alias for Lua's "function()", and should be a valid Lua program. There is no need to append "end" to the end of the string.

As f.fn is a string-lambda, it doesn't get syntax-checked at compile-time, which is annoying, but it does mean you can construct it on the fly for metaprogramming at runtime.

Example:

```
f.fn("() return nil")
> function
f.fn("(x, y) return {x, y}")(1, 2)
> {1, 2}
```

### ```f.let({x = 12}, function() print(x) end)```

f.let takes a table of values, and a function. It binds the values in place, and then calls the function, before unbinding the variables again. Any variables overridden by let get restored.

Example:

```
f.let({x = 2}, function() return x end)
> 2
f.let({x = 3, y = 4}, f.fn("() return x + y"))
> 7
```

### ```.f.cond(condlist)```

f.cond takes a condlist, an array of two part tables, where the left side is boolean. For the first pair where the left side is true, the right side is returned. If no true value can be found, returns nil.

Example:

```
f.cond({
  {x == 2, x},
  {x < 4, y}
})
```

---

## License

See [LICENSE](LICENSE).
