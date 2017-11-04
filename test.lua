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
assert(type(f.car({})) == "table")
assert(#f.car({}) == 0)

-- f.head(table), alias for f.car
assert(f.head({2, 3, 4}) == 2)
assert(type(f.head({})) == "table")
assert(#f.head({}) == 0)

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
