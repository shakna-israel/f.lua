f = require "f"

-- f.cons(1, nil)
assert(type(f.cons(1)) == "table")
assert(f.cons(1)[1] == 1)
assert(#f.cons(1) == 1)

-- f.cons(1, table)
assert(type(f.cons(1, {2})) == "table")
assert(f.cons(1, {2})[1] == 1)
assert(f.cons(1, {2})[2] == 2)
assert(#f.cons(1, {2}) == 2)

-- f.car(table)
assert(f.car({2, 3, 4}) == 2)
assert(f.car({}) == nil)
assert(type(f.car({x = 1}) == "table"))

-- f.head(table), alias for f.car
assert(f.head({2, 3, 4}) == 2)
assert(f.head({}) == nil)
assert(type(f.head({x = 1}) == "table"))

-- f.cdr(table)
assert(f.cdr({1, 2, 3})[1] == 2)
assert(f.cdr({1, 2, 3})[2] == 3)
assert(#f.cdr({1, 2, 3}) == 2)
assert(#f.cdr({}) == 0)
assert(type(f.cdr({})) == "table")

-- f.rest(table), alias for cdr
assert(f.rest({1, 2, 3})[1] == 2)
assert(f.rest({1, 2, 3})[2] == 3)
assert(#f.rest({1, 2, 3}) == 2)
assert(#f.rest({}) == 0)
assert(type(f.rest({})) == "table")

-- f.elif(predicate, a, b)
assert(f.elif(true, 1, 2) == 1)
assert(f.elif(false, 1, 2) == 2)

-- f.fn("(args) return x")(calls)
assert(type(f.fn("(x) return x")) == "function")
assert(f.fn("(x) return x")(1) == 1)

-- f.let(table, functor)
assert(f.let({x = 22}, function() return x end) == 22)
assert(f.let({x = 12}, f.fn("() return x")) == 12)

-- f.cond(condlist)
assert(f.cond({{false, 1}, {true, 2}}) == 2)
assert(f.cond({{true, 1}, {true, 2}}) == 1)
assert(f.cond({{false, 1}, {false, 2}}) == nil)
