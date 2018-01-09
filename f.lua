--- f.lua aims to be the most complete functional extension library for Lua, whilst remaining fundamentally Lua.
-- It's fast, safe, unsurprising and fully-featured, with let statements, string lambdas, and currying. Whether you miss LISP or Haskell whilst working with Lua, this should scratch your itch, without making Lua's VM come to a screeching halt.
-- @module f.lua
-- @set sort=true

local load = loadstring or load
local unpack = unpack or table.unpack

local prettyprint
prettyprint = function(val, outstring)
  local msg = ""
  if type(val) == "table" then
    msg = msg .. "{"
    for k, v in pairs(val) do
      if v == val then
        msg = msg .. "\t<self-reference>,\n"
      else
        msg = msg .. "\t" .. prettyprint(k, true) .. " = " .. prettyprint(v, true) .. ",\n"
      end
    end
    msg = msg .. "}"
  else
    if type(val) == "function" then
      msg = msg .. "<function>: " .. tostring(val)
    elseif type(val) == "string" then
      msg = msg .. '"' .. val .. '"'
    elseif type(val) == "number" then
      msg = msg .. tostring(val)
    elseif val == nil then
      msg = msg .. "nil"
    elseif type(val) == "boolean" then
      msg = msg .. tostring(val)
    elseif type(val) == "userdata" then
      msg = msg .. "<userdata>: " .. tostring(val)
    elseif type(val) == "thread" then
      msg = msg .. "<thread>: " .. tostring(val)
    end
  end
  if outstring == nil then
    print(msg)
  else
    return msg
  end
end

--- Convenience
-- @section convenience

--- A benchmarking tool, it is highly not recommended to run impure functions through it.
-- @function timeit
-- @tparam function functor The function to benchmark. It should be pure.
-- @param ... Arguments to parse to functor
-- @treturn number Seconds taken on average across 100 runs.
local timeit
timeit = function(functor, ...)
  local start = os.clock()
  for i=1, 100 do
    functor(...)
  end
  local fin = os.clock()
  return (fin - start) / 100
end

--- Return a self-caching version of a function
-- @function memoize
-- @tparam function functor The function whose return data should get cached
-- @treturn function Returns a function that caches data the first time it is called, and just returns that if the arguments are the same the next time around
local memoize
do
  local cache = {}
  memoize = function(functor)
    cache[functor] = {}
    return function(...)
      local cached = false
      local args = {...}

      local data
      -- Check if these arguments are cached.
      for k, v in pairs(cache[functor]) do
        if not cached then
          if #k == #args then
            local same = true
            for ix, arg in ipairs(args) do
              if k[ix] ~= arg then
                same = false
              end
            end
            if same then
              cached = true
              data = v
            end
          end
        end
      end

      if cached then
        return unpack(data)
      else
        local store = {functor(...)}
        cache[functor][args] = store
        return unpack(store)
      end
    end
  end
end

--- Add a vendor path to Lua
-- @function vend
-- @tparam string vendor
-- @treturn nil
local vend
vend = function(vendor)
  local vendor = vendor or "vendor"
  local version = _VERSION:match("%d+%.%d+")
  package.path = vendor .. '/share/lua/' .. version .. '/?.lua;' .. vendor .. '/share/lua/' .. version .. '/?/init.lua;' .. package.path
  package.cpath = vendor .. '/lib/lua/' .. version .. '/?.so;' .. package.cpath
end

--- A simple type-guard system
-- Takes a series of strings, that should be types, in the order the function being guarded would receive them.
-- Then it optionally takes another string prepended with "->" for the return type.
-- Finally it must receive a function to guard.
-- @function guard
-- @treturn function
local guard
guard = function(...)
  local args = {...}
  local functor = table.remove(args)
  local ret = nil
  for ix, val in ipairs(args) do
    if val:sub(1, 2) == "->" then
      if ret == nil then
        ret = table.remove(args, ix)
      else
        assert(false, "GuardError: Multiple return types given, expected 1.")
      end
    end
  end
  return function(...)
    local arglist = {...}
    for ix, kind in ipairs(args) do
      local val = arglist[ix]
      assert(type(val) == kind, string.format("GuardError: Expected argument number %d to be of type %s, but received %s(%s).", ix, kind, type(val), val))
    end
    if ret ~= nil then
      local r = functor(unpack(arglist))
      assert(type(r) == ret:sub(3), string.format("GuardError: Expected return value to be of type %s, but received %s(%s)", ret:sub(3), type(r), r))
      return r
    else
      return functor(unpack(arglist))
    end
  end
end

--- Converts an iterable into a coroutine
-- @function iter
-- @param iter string or table iterable
-- @treturn thread
local iter
iter = function(obj)
  assert(type(obj) == "table" or type(obj) == "string")
  if type(obj) == "table" then
    return coroutine.create(function()
      for k, v in pairs(table) do
        coroutine.yield(v)
      end
    end)
  else
    return coroutine.create(function()
      for c in obj:gmatch(".") do
        coroutine.yield(c)
      end
    end)
  end
end

--- Clones an object & its metatable
-- @function clone
-- @param o An object
-- @return A copy of the object
local clone
clone = function(o)
  if type(o) == "function" then
    return load(string.dump(o))
  elseif type(o) == "table" then
    local ret = {}
    if getmetatable(o) ~= nil then
      local mt = clone(getmetatable(o))
      setmetatable(ret, mt)
    end
    for k, v in pairs(o) do
      ret[k] = clone(v) -- Should handle recursive copies.
    end
    return ret
  else
    return o
  end
end

--- String Lambda!
-- e.g. f.fn("(x, y) print(x, y)")(2, 3)
-- @function fn
-- @tparam string s A string starting with parentheses as shown in the example.
-- @treturn function
local fn
fn = function(s)
  return assert(load("return function " .. tostring(s) .. " end"), "fn was unable to build a valid function from: " .. tostring(s))()
end

--- Autoclosing files and threads
-- @function with
-- @param entry Filenme string or thread object
-- @tparam string permissions
-- @tparam function functor
local with
with = function(entry, permissions, functor)
  assert(type(entry) == "string" or type(entry) == "thread")
  assert(type(permissions) == "string")
  assert(type(functor) == "function")

  -- With can close over a file.
  if type(entry) == "string" then
    local file = io.open(filepath, permissions)
    ret = {functor(file)}
    if file then file:close() end
    return unpack(ret)
  else
    -- With can iterate over a coroutine.
    local results = {}
    while coroutine.status(entry) == "suspended" do
      local res = {functor(coroutine.resume(entry))}
      if #res > 1 then
        results[#results + 1] = res
      else
        results[#results + 1] = res[1] or nil
      end
    end
    return results
  end
end

--- Coroutines
-- @section coroutines

--- Wrap a function in a coroutine
-- @function co
-- @tparam function functor
-- @treturn thread Returns coroutine.wrap(functor)
local co = {}
setmetatable(co, {
  __call = function(functor)
    return coroutine.wrap(functor)
  end
})

--- Create a coroutine
-- @function co.c
-- @tparam function functor
-- @treturn thread Returns coroutine.create(functor)
co.c = function(functor)
  return coroutine.create(functor)
end

--- Toggle a coroutine's resume
-- @function co.t
-- @tparam thread functor
-- @return Either returns the coroutine.resume of functor, or nil if the thread is dead.
co.t = function(thread)
  assert(type(thread) == "thread", "co.t expects a thread, but received a " .. type(thread))
  if coroutine.status(thread) == "suspended" then
    return coroutine.resume(thread)
  elseif coroutine.status(thread) == "dead" then
    return nil
  end
end

--- Check a coroutine is running
-- @function co.r
-- @treturn boolean Returns coroutine.running()
co.r = function()
  return coroutine.running()
end

--- Functional Essentials
-- @section essentials

--- Shuffles a given table, using Fisher-Yates, a simple swapping algo.
-- @function shuffle
-- @tparam table tbl
-- @treturn table A shuffled table
local shuffle
shuffle = function(tbl)
  assert(type(tbl) == "table", "shuffle expected a table, but received: " .. type(tbl))
  for i = #tbl, 1, -1 do
    local r = math.random(#tbl)
    tbl[i], tbl[r] = tbl[r], tbl[i]
  end
  return tbl
end

--- A tail-call elimination safe way of calling the calling function.
-- e.g. "function() recur()() end" is a infinitely recursive function.
-- @function recur
-- @treturn function Returns the containing function.
local recur
recur = function()
  return debug.getinfo(2, "f").func
end

--- A currying function
-- @function curry
-- @tparam function a
-- @tparam function b
-- @treturn function A function that merges a around b, returning a new function. e.g. curry(print, string.format) is a kind of printf.
local curry
curry = function(a, b)
  assert(type(a) == "function", "curry expects a to be a function, but received a " .. type(a))
  assert(type(b) == "function", "curry expects b to be a function, but received a " .. type(b))
  return function(...)
    return a(b(...))
  end
end

--- A localised value binding function
-- @function let
-- @tparam table values An array of pairs of values, with the name on the left, and value on the right.
-- @tparam function functor The function to call, with the new value bindings.
-- @return Returns the return of the functor.
local let
let = function(values, functor)
  assert(type(functor) == "function")
  -- Preperations
  backups = {}
  for k, v in pairs(values) do
    if _G[k] ~= nil then
      backups[k] = _G[k]
      _G[k] = clone(v)
    else
      _G[k] = clone(v)
    end
  end

  -- Capture all values
  ret = {functor()}

  -- Restore normal values
  for k, v in pairs(values) do
    _G[k] = nil
  end
  for k, v in pairs(backups) do
    _G[k] = v
  end
  return unpack(ret)
end

--- A better chained else-if function.
-- @function cond
-- @param condlist A condlist is a table, containing other tables. The inner tables are pairs, where the key is a boolean. If it is true, then it's value is returned.
-- @return Returns a value where the key is true.
local cond
cond = function(condlist)
  assert(type(condlist) == "table", "cond expects condlist to be a table, but received a " .. type(condlist))
  assert(condlist[1])
  for k, v in pairs(condlist) do
    assert(type(v) == "table", "cond expects a table of tables. However an item was not a table it was a " .. type(v))
    assert(#v == 2, "cond expects a table of pairs, but an item didn't have two items, it had " .. tostring(#v))
    assert(type(k) == "number", "cond expects the enclosing table to act like an array, but found key " .. tostring(k))
  end
  
  for i=1, #condlist do
    if condlist[i][1] == true then
      return condlist[i][2]
    end
  end
  return nil
end

--- Apply a function recursively to a list.
-- @function apply
-- @param functor The function to recursively call against the list
-- @tparam table args The list of arguments to be recursively called.
-- @return Returns a single value created by the recursive call.
local apply
apply = function(functor, args)
  assert(type(args) == "table", "apply expects args to be a table, but received " .. type(args))
  assert(type(functor) == "function" or type(getmetatable(functor).__call) == "function", "apply expects functor to be a function")
  return functor(unpack(args))
end

--- Create a list by recursively calling a function against a list
-- @function map
-- @tparam function functor The function to be called against
-- @tparam table args The arguments to call against the function
-- @treturn table Returns a list
local map
map = function(functor, args)
  assert(type(args) == "table", "map expects args to be a table, but received a " .. type(args))
  assert(type(functor) == "function" or type(getmetatable(functor).__call) == "function", "map expects functor to be a function")
  ret = {}
  for k, v in pairs(args) do
    ret[#ret + 1] = functor(v)
  end
  return ret
end

--- Filter a list
-- @function filter
-- @tparam function functor A function that should return a boolean when given a value from the args list. If true, the value is added to the return list, if not, it gets dropped.
-- @tparam table args The list to filter
-- @treturn table Returns the filtered list
local filter
filter = function(functor, args)
  assert(type(args) == "table", "filter expects args to be a table, but received a " .. type(args))
  assert(type(functor) == "function", "filter expects functor to be a function")
  ret = {}
  for _, v in pairs(args) do
    if functor(v) then
      ret[#ret + 1] = v
    end
  end
  return ret
end

--- A functional else-if construct
-- @function elif
-- @tparam boolean predicate
-- @param a Returned if predicate is true
-- @param b Returned if predicate is false
-- @return Either a or b
local elif
elif = function(predicate, a, b)
  assert(type(predicate) == "boolean", "elif expects predicate to be boolean, but received " .. type(predicate))
  if predicate then
    return a
  else
    return b
  end
end

--- A list-creation tool
-- @function cons
-- @param val Any value
-- @tparam[opt] table tbl The list to join to. If one doesn't exist, it will be created.
-- @treturn table The list that is generated.
local cons
cons = function(val, tbl)
  if tbl == nil then
    tbl = {}
  end
  assert(type(tbl) == "table", "cons expects tbl to be a table, but received a " .. type(tbl))
  table.insert(tbl, 1, val)
  return tbl
end

--- Access the first value of an array.
-- @function car
-- @tparam table tbl The list to be accessed
-- @return The first element of the list.
local car
car = function(tbl)
  assert(type(tbl) == "table", "car expects tbl to be a table, but received a " .. type(tbl))
  local ix, v = next(tbl)
  if ix == 0 or ix == 1 then
    return v
  elseif ix == nil then
    return nil
  else
    return ix, v
  end
end

--- Access the "tail" of a list
-- @function cdr
-- @tparam table tbl The list to be accessed
-- @treturn table Returns all but the first element in the list.
local cdr
cdr = function(tbl)
  assert(type(tbl) == "table", "cdr expects tbl to be a table, but received a " .. type(tbl))
  return { unpack(tbl, 2) }
end

--- Reverses an iterable
-- @function reverse
-- @param obj string or table
-- @return The reverse string or table
local reverse
reverse = function(obj)
  assert(type(obj) == "string" or type(obj) == "table", "Can only reverse strings or tables.")
  if type(obj) == "string" then
    return obj:reverse()
  else
    local ret = {}
    for i = 1, math.floor(#obj / 2) do
      ret[i], ret[#obj - i + 1] = obj[#obj - i + 1], obj[i]
    end
    return ret
  end
end

--- Access a range from an interable
-- @function nth
-- @param iterable An iterable, such as a string or table.
-- @tparam number begin
-- @tparam number fin
-- @return A selection of the iterable
local nth
nth = function(iterable, begin, fin)
  assert(type(begin) == "number" and math.ceil(begin) == begin, "nth needs a valid range number.")
  if fin ~= nil then
    assert(type(fin) == "number" and math.ceil(fin) == fin, "nth needs a valid range number.")
  end

  local toString = false
  -- Convert string to table
  if type(iterable) == "string" then
    local tmp = {}
    for c in iterable:gmatch(".") do tmp[#tmp + 1] = c end
    iterable = tmp
    toString = true
  end

  if fin == nil then
    fin = #iterable
  end

  if fin < 0 then
    fin = #iterable + fin
  end

  local result = {}
  for i=begin, fin do
    result[#result + 1] = iterable[i]
  end
  
  if toString then
    return table.concat(result)
  else
    return result
  end
end

--- foldr
-- @function foldr
-- @tparam function functor
-- @tparam table tbl
-- @param val The seed value
-- @return The folded value
local foldr
foldr = function(functor, tbl, val)
  assert(type(functor) == "function", "Functor must be a function.")
  assert(type(tbl) == "table", "foldr expects a table.")
  for k, v in pairs(tbl) do
    val = functor(v, val)
  end
  return val
end

--- Reduce a table to a set, that is, every item must be unique.
-- @function set
-- @tparam table tbl A simple array e.g. {"Hello", "World", "Hello", "World"}
-- @treturn table A simple array, with only unique items. e.g. {"Hello", "World"}
local set
set = function(tbl)
  assert(type(tbl) == "table", "Set only works on tables, but received: " .. type(tbl))
  local tmp = {}
  for _, v in ipairs(tbl) do
    tmp[v] = true
  end
  local ret = {}
  for k, _ in pairs(tmp) do
    ret[#ret + 1] = k
  end
  return ret
end

--- Swap key and values in a table.
-- @function ktov
-- @tparam table tbl
-- @treturn table A key-value swapped table
local ktov
ktov = function(tbl)
  local r = {}
    for k, v in pairs(tbl) do
      r[v] = k
    end
  return r
end

--- Remove a set of values from a table
-- @function exclude
-- @tparam table ex_tbl The values to remove e.g. {1, 2, 3}
-- @tparam table tbl The table being processed e.g. {1, 2, 3, 4, 5}
-- @treturn table The new table, e.g. {4, 5}
local inarray -- depends on this, which is in the Predicates section

local exclude
exclude = function(ex_tbl, tbl)
  local r = {}
  for _, v in ipairs(tbl) do
    if not inarray(ex_tbl, v) then
      r[#r + 1] = v
    end
  end
  return r
end

--- Mathematical Operators
-- @section maths

--- Wraps math.random, unless x is a table, in which case it gives a
-- random item from that table.
-- @function random
-- @param[opt] x
-- @param[opt] y
-- @return object
local random = {}
setmetatable(random, {
  __call = function(self, x, y)
  if x == nil and y == nil then
    return math.random()
  end
  if type(x) == "table" then
    if y == nil then
      return x[math.random(#x)]
    else
      return x[math.random(y)]
    end
  else
    if y == nil then
      return math.random(x)
    else
      return math.random(x, y)
    end
  end
end})

--- Given a weighted table, (e.g. {"hello" = 2, "cat" = 1, "dog" = 3}), returns a random item (e.g. "dog"), whilst respecting the weighted chance.
-- @function random.weighted
-- @tparam table tbl
-- @return Returns one key from the table.
random.weighted = function(tbl)
  assert(type(tbl) == "table", "random.weighted expected a weighted table. But received a: " .. type(tbl))
  for k, v in pairs(tbl) do
    assert(type(v) == "number", "random.weighted expected values in table to be numbers for weight. But received: " .. type(v))
  end
  local weighted = {}
  for k, v in pairs(tbl) do
    for i=1, v do
      weighted[#weighted + 1] = k
    end
  end
  local ret = weighted[math.random(#weighted)]
  return ret
end

--- Clamp a number between two others
-- @function clamp
-- @tparam number x
-- @tparam number n
-- @tparam number y
-- @treturn number Returns the number in the "middle" after sorting. e.g. clamp(5, 0, 10) == 5
local clamp
clamp = function(x, n, y)
  local t = {x, n, y}
  table.sort(t)
  return t[2]
end

--- Round a number to a certain number of places
-- @function round
-- @tparam number num The number to round
-- @tparam number depth The number of decimal places to round to
-- @treturn number The rounded number is returned
local round
round = function(num, depth)
  depth = depth or 2
  return tonumber(string.format("%." .. tostring(depth) .. "f", num))
end

--- Addition operator
-- @function add
-- @tparam number a
-- @tparam number b
-- @treturn number Return a + b
local add
add = function(a,b) return a + b end

--- Subtraction operator
-- @function sub
-- @tparam number a
-- @tparam number b
-- @treturn number Return a - b
local sub
sub = function(a, b) return a - b end

--- Multiplication operator
-- @function mul
-- @tparam number a
-- @tparam number b
-- @treturn number Return a * b
local mul
mul = function(a, b) return a * b end

-- We want div(a, b) and div.int(a, b) for integer division.
local div = {}
setmetatable(div,
    {
      __call = function(self, a, b) return a / b end
    })

--- Division operator
-- @function div
-- @tparam number a
-- @tparam number b
-- @treturn number Returns a / b

--- Integer division operator
-- @function div.int
-- @tparam number a
-- @tparam number b
-- @treturn number Returns math.floor(a/b)
div.int = function(a, b) return math.floor(a/b) end

--- Operators
-- @section operators

--- Greater Than operator
-- @function gt
-- @param a
-- @param b
-- @treturn boolean
local gt
gt = function(a,b) return a > b end

--- Great Than or Equal operator
-- @function gte
-- @param a
-- @param b
-- @treturn boolean
local gte
gte = function(a,b) return a >= b end

--- Less Than operator
-- @function lt
-- @param a
-- @param b
-- @treturn boolean
local lt
lt = function(a,b) return a < b end

--- Less Than or Equal operator
-- @function lte
-- @param a
-- @param b
-- @treturn boolean
local lte
lte = function(a,b) return a <= b end

--- Not Equal operator
-- @function ne
-- @param a
-- @param b
-- @treturn boolean
local ne
ne = function(a,b) return a ~= b end

--- Mod Operator
-- @function mod
-- @param a
-- @param b
-- @treturn number Returns a % b
local mod
mod = function(a, b) return a % b end

--- Unary operator
-- @function unary
-- @param a
-- @return Returns -a
local unary
unary = function(a) return -a end

--- Powerto operator
-- @function pow
-- @param a
-- @param b
-- @return Returns a^b
local pow
pow = function(a, b) return a^b end

--- Or operator
-- @function xor
-- @param a
-- @param b
-- @return Returns a or b
local xor
xor = function(a, b) return a or b end

--- And operator
-- @function xnd
-- @param a
-- @param b
-- @return Returns a and b
local xnd
xnd = function(a, b) return a and b end

--- Not operator
-- @function xnt
-- @param a
-- @return Returns not a
local xnt
xnt = function(a) return not a end

--- Ports
-- @section ports

local port = {}

--- Override print and io.write with port:write for a given port
-- @function port.with_output
-- @param port A port-like object
-- @tparam function functor
-- @return Returns functor's return value.
port.with_output = function(port, functor)
  local printer = function(nl, sep, ...)
    msg = port:read() or ""
    local args = {...}
    for i, v in ipairs(args) do
      if #msg > 0 and msg:sub(-1, -1) ~= "\n" then
        msg = msg .. sep .. tostring(v)
      else
        msg = msg .. tostring(v)
      end
    end
    if nl then
      port:write(msg .. "\n")
    else
      port:write(msg)
    end
  end
  giowrite = io.write
  io.write = function(...)
    printer(false, "", ...)
  end
  local gprint = print
  print = function(...)
    printer(true, "\t", ...)
  end
  local ret = {functor()}
  print = gprint
  io.write = giowrite
  port:close()
  return unpack(ret)
end

--- Override io.read with port:read for a given port
-- @function port.with_input
-- @param port A port-like object
-- @tparam function functor
-- @return Returns functor's return value.
port.with_input = function(port, functor)
  local ginput = io.read
  io.read = function(...)
    return port:read(...)
  end
  local ret = {functor()}
  io.read = ginput
  port:close()
  return unpack(ret)
end

--- Create a port that can be read from
-- @function port.make_input
-- @tparam function read_func
-- @tparam function close_func
-- @return Returns port-like object for reading
port.make_input = function(read_func, close_func)
  local port = {}
  port.read = read_func
  port.close = close_func
  return port
end

--- Create a port that can read and write
-- @function port.make_output
-- @tparam function write_func
-- @tparam function read_func
-- @tparam function close_func
-- @return Retuns port-like object for writing and reading
port.make_output = function(write_func, read_func, close_func)
  local port = {}
  port.write = write_func
  port.read = read_func
  port.close = close_func
  return port
end

--- Override io.read with a string
-- @function port.from_string
-- @tparam string str
-- @tparam function functor
-- @return Returns the output of functor
port.from_string = function(str, functor)
  local ginput = io.read
  io.read = function()
    return str
  end
  local ret = {functor()}
  io.read = ginput
  return unpack(ret)
end

--- An iterator that can be used in for-loops to read over a port-like object
-- @function port.iter
-- @param port A port-like object
-- @param n Position of iteration
-- @param data Where the data is stored in the port-like object
port.iter = function(port, n, data)
  if data == nil then data = "data" end
  if n == nil then n = 1 end
  if n <= #port[data] then
    local d = port[data]:sub(n, n)
    n = n + 1
    return n, d, data
  end
end

--- Predicates
-- @section predicates

--- Test equivalence
-- @function eq
-- @param a
-- @param b
-- @treturn boolean Returns true if the two given values are equivalent, even if they are different tables.
local eq
eq = function(a, b)
  if type(a) == "table" and type(b) == "table" then
    if #a == #b then
      for key_a, val_a in pairs(a) do
        for key_b, val_b in pairs(b) do
          if key_a ~= key_b then
            return false
          elseif val_a ~= val_b then
            return false
          end
        end
      end
      return true
    else
      return false
    end
  else
    return a == b
  end
end

--- Check if a value occurs in a list
-- @function inarray
-- @tparam table tbl Table to process
-- @param v Value to check for
-- @treturn boolean
inarray = function(tbl, v)
  for _, val in ipairs(tbl) do
    if v == val then return true end
  end
  return false
end

--- Predicate to test string type
-- @function isstring
-- @param x The object to test if is a string
-- @treturn boolean
local isstring
isstring = function(x)
  return type(x) == "string"
end

--- Predicate to test number type
-- @function isnumber
-- @param x The object to test if is a number
-- @treturn boolean
local isnumber
isnumber = function(x)
  return type(x) == "number"
end

--- Returns true or false, given any object, if it is a positive number
-- @function ispositive
-- @param x
-- @treturn boolean
local ispositive
ispositive = function(x)
  if isnumber(x) and x > 0 then
    return true
  else
    return false
  end
end

--- Returns true or false, given any object, if it is a negative number
-- @function isnegative
-- @param x
-- @treturn boolean
local isnegative
isnegative = function(x)
  if isnumber(x) and x < 0 then
    return true
  else
    return false
  end
end

--- Returns true or false, given any object, if it is 0
-- @function iszero
-- @param x
-- @treturn boolean
local iszero
iszero = function(x)
  if x == 0 then
    return true
  else
    return false
  end
end

--- Predicate to test function type
-- @function isfunction
-- @param x The object to test if is a function
-- @treturn boolean
local isfunction
isfunction = function(x)
  return type(x) == "function"
end

--- Predicate to test boolean type
-- @function isboolean
-- @param x The object to test if is a boolean
-- @treturn boolean
local isboolean
isboolean = function(x)
  return type(x) == "boolean"
end

--- Predicate to test nil type
-- @function isnil
-- @param x The object to test if is a nil
-- @treturn boolean
local isnil
isnil = function(x)
  return x == nil
end

--- Predicate to test table type
-- @function istable
-- @param x The object to test if is a table
-- @treturn boolean
local istable
istable = function(x)
  return type(x) == "table"
end

--- Predicate to test thread type
-- @function isthread
-- @param x The object to test if is a thread
-- @treturn boolean
local isthread
isthread = function(x)
  return type(x) == "thread"
end

--- Predicate to test userdata type
-- @function isuserdata
-- @param x The object to test if is a userdata
-- @treturn boolean
local isuserdata
isuserdata = function(x)
  return type(x) == "userdata"
end

--- Predicate to test file type
-- @function isfile
-- @param x The object to test if is a file
-- @treturn boolean
local isfile
isfile = function(x)
  return io.type(x) == "file"
end

-- Because we have so many functions that rely on math.random,
-- we seed it upon require.
math.randomseed(os.time())

local returnData

local pollute
local unpollute
do
  local cache = {}

  --- Pollute the global namespace with f.lua's functions.
  -- @function pollute
  -- @treturn nil No return value.
  pollute = function()
    for k, v in pairs(returnData) do
      if _G[k] ~= nil then cache[k] = _G[k] end
      _G[k] = v
    end
  end

  --- Undo pollution of the global namespace by f.pollute.
  -- @function unpollute
  -- @treturn nil No return value.
  unpollute = function()
    for k, v in pairs(returnData) do
      if cache[k] ~= nil then
        _G[k] = cache[k]
      else
        _G[k] = nil
      end
    end
  end
end

returnData = {
  mod = mod,
  unary = unary,
  pow = pow,
  xor = xor,
  xnd = xnd,
  xnt = xnt,
  vend = vend,
  guard = guard,
  iter = iter,
  foldr = foldr,
  reverse = reverse,
  nth = nth,
  clone = clone,
  prettyprint = prettyprint,
  elif = elif,
  cons = cons,
  car = car,
  head = car,
  cdr = cdr,
  rest = cdr,
  fn = fn,
  let = let,
  cond = cond,
  apply = apply,
  map = map,
  filter = filter,
  reduce = filter,
  curry = curry,
  eq = eq,
  recur = recur,
  with = with,
  co = co,
  isstring = isstring,
  isnumber = isnumber,
  isfunction = isfunction,
  isboolean = isboolean,
  isnil = isnil,
  istable = istable,
  isuserdata = isuserdata,
  isfile = isfile,
  add = add,
  sub = sub,
  mul = mul,
  div = div,
  gt = gt,
  gte = gte,
  lt = lt,
  lte = lte,
  ne = ne,
  port = port,
  clamp = clamp,
  round = round,
  ispositive = ispositive,
  isnegative = isnegative,
  iszero = iszero,
  random = random,
  shuffle = shuffle,
  set = set,
  ktov = ktov,
  inarray = inarray,
  exclude = exclude,
  timeit = timeit,
  memoize = memoize,
  pollute = pollute,
  unpollute = unpollute,
}

return returnData
