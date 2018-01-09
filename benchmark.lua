local f = require "f"

--- Micro Benchmarking
-- Microbenchmarks are only good for a general feel of something.
-- They are not accurate, or a definitive pointer for how fast a function is.

local t = 0
local total = 0
local fcount = 0

t = f.timeit(f.clone, {})
print("clone: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.fn, "() return true")
print("fn: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.guard, "string", "string", "->string", function(a, b) return a .. b end)
print("guard: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.iter, "Hello")
print("iter: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.apply, f.add, {1, 2, 3, 4, 5})
print("apply: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.car, {1, 2})
print("car: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.cdr, {1, 2})
print("cdr: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.cond, {
  {false, 1},
  {true, 2},
})
print("cond: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.cons, 20, {1, 2, 3})
print("cons: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.curry, print, string.format)
print("curry: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.elif(true, function() return 12 end, function() return 10 end))
print("elif: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.exclude, {1,2,3}, {1,2,3,4,5})
print("exclude: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.filter, function(x) return true end, {1,2,3,4,5})
print("filter: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.foldr, f.mul, {1, 2, 3, 4, 5}, 1)
print("foldr: " .. tostring(t))
total = total + t
fcount = fcount + 1

t = f.timeit(f.ktov, {1, 2, 3})
print("ktov: " .. tostring(t))
total = total + t
fcount = fcount + 1

print("Total runtime: " .. tostring(total))
print("Average runtime: " .. tostring(total / fcount))