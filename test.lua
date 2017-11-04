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
