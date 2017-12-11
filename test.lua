f = require "f"

-- f.prettyprint
assert(f.prettyprint(10, true) == "10")
assert(f.prettyprint("10", true) == '"10"')
assert(f.prettyprint(true, true) == "true")

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

-- f.apply(functor, args)
assert(f.apply(math.min, {2, 1, 3}) == 1)

-- f.map(functor, args)
assert(type(f.map(function(x) return x*2 end, {2})) == "table")
assert(f.map(function(x) return x*2 end, {2})[1] == 4)
assert(#f.map(function(x) return x*2 end, {2}) == 1)

-- f.filter(functor, args)
assert(f.filter(function(x) if type(x) == "number" then return true else return false end end, {'', '', 2})[1] == 2)
assert(#f.filter(function(x) if type(x) == "number" then return true else return false end end, {'', '', 2}) == 1)

-- f.curry(a, b)
assert(type(f.curry(io.write, string.format) == "function"))

-- f.eq(a, b) Comparison by value, not reference.
assert(f.eq(1, 1) == true)
assert(f.eq(1, 2) == false)
assert(f.eq({1, 1}, {1, 2}) == false)
assert(f.eq({1}, {1}) == true)

--f.recur() Tail-call safe anonymouse recursion.
local tmp = function(x)
  if x == 0 then
    return true
  else
    return f.recur()(x - 1)
  end
end
assert(tmp(20000) == true)
tmp = nil

-- Coroutines are just wrappers, so equivalence is good enough.
assert(type(f.co.c(function() return end)) == "thread", "f.co.c didn't create a thread.")

-- f.with(filepath, permissions, functor)
-- This API may change in later major versions, to support more than just files.
-- TODO: Test tmp file?

-- Predicates: predicate(val) -> boolean
assert(f.isstring("") == true)
assert(f.isstring(1) == false)

assert(f.isnumber(10) == true)
assert(f.isnumber('a') == false)

assert(f.isfunction(function() return nil end) == true)
assert(f.isfunction(nil) == false)

assert(f.isboolean(false) == true)
assert(f.isboolean(nil) == false)

assert(f.isnil(nil) == true)
assert(f.isnil({}) == false)

assert(f.istable({}) == true)
assert(f.istable('') == false)

assert(f.isuserdata(io.stdin) == true)
assert(f.isuserdata({}) == false)

assert(f.isfile(io.stdin) == true)
assert(f.isfile('') == false)

-- Operators
-- Almost all of these have so simple an implementation
-- that testing them seems somewhat ridiculous.
-- It's here for:
-- * API compatibility.
-- * Testing the called function runs at all.

assert(f.add(2, 4) == 2 + 4)
assert(f.sub(6, 4) == 6 - 4)
assert(f.mul(2, 2) == 2 * 2)
assert(f.div(2, 3) == 2 / 3, "f.div failed. Ignore the questionmark in traceback, probably to do with the metatable. Look there for the bug.")
assert(f.div.int(2, 3) == math.floor(2 / 3)) -- Note the overload!
assert(f.gt(1, 2) == (1 > 2))
assert(f.gte(1, 1) == (1 >= 1))
assert(f.lt(1, 2) == (1 < 2))
assert(f.lte(1, 1) == (1 <= 1))
assert(f.ne(1, 2) == (1 ~= 2))
