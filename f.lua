--- f.lua aims to be the most complete functional extension library for Lua, whilst remaining fundamentally Lua.
-- It's fast, safe, unsurprising and fully-featured, with let statements, string lambdas, and currying. Whether you miss LISP or Haskell whilst working with Lua, this should scratch your itch, without making Lua's VM come to a screeching halt.
-- @module f.lua
-- @set sort=true

local load = loadstring or load
local unpack = unpack or table.unpack

local f = {}

f.prettyprint = function(val, outstring)
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
f.timeit = function(functor, ...)
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
do
  local cache = {}
  f.memoize = function(functor)
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



--- A simple type-guard system
-- Takes a series of strings, that should be types, in the order the function being guarded would receive them.
-- Then it optionally takes another string prepended with "->" for the return type.
-- Finally it must receive a function to guard.
-- @function guard
-- @treturn function
f.guard = function(...)
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
f.iter = function(obj)
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
f.clone = function(o)
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
f.fn = function(s)
  return assert(load("return function " .. tostring(s) .. " end"), "fn was unable to build a valid function from: " .. tostring(s))()
end

--- Autoclosing files and threads
-- @function with
-- @param entry Filenme string or thread object
-- @tparam string permissions
-- @tparam function functor
f.with = function(entry, permissions, functor)
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
f.co = {}
setmetatable(f.co, {
  __call = function(functor)
    return coroutine.wrap(functor)
  end
})

--- Create a coroutine
-- @function co.c
-- @tparam function functor
-- @treturn thread Returns coroutine.create(functor)
f.co.c = function(functor)
  return coroutine.create(functor)
end

--- Toggle a coroutine's resume
-- @function co.t
-- @tparam thread functor
-- @return Either returns the coroutine.resume of functor, or nil if the thread is dead.
f.co.t = function(thread)
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
f.co.r = function()
  return coroutine.running()
end

--- Functional Essentials
-- @section essentials

--- Shuffles a given table, using Fisher-Yates, a simple swapping algo.
-- @function shuffle
-- @tparam table tbl
-- @treturn table A shuffled table
f.shuffle = function(tbl)
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
f.recur = function()
  return debug.getinfo(2, "f").func
end

--- A currying function
-- @function curry
-- @tparam function a
-- @tparam function b
-- @treturn function A function that merges a around b, returning a new function. e.g. curry(print, string.format) is a kind of printf.
f.curry = function(a, b)
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
f.let = function(values, functor)
  assert(type(functor) == "function")
  -- Preperations
  backups = {}
  for k, v in pairs(values) do
    if _G[k] ~= nil then
      backups[k] = _G[k]
      _G[k] = f.clone(v)
    else
      _G[k] = f.clone(v)
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
f.cond = function(condlist)
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
f.apply = function(functor, args)
  assert(type(args) == "table", "apply expects args to be a table, but received " .. type(args))
  assert(type(functor) == "function" or type(getmetatable(functor).__call) == "function", "apply expects functor to be a function")
  return functor(unpack(args))
end

--- Create a list by recursively calling a function against a list
-- @function map
-- @tparam function functor The function to be called against
-- @tparam table args The arguments to call against the function
-- @treturn table Returns a list
f.map = function(functor, args)
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
f.filter = function(functor, args)
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
f.elif = function(predicate, a, b)
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
f.cons = function(val, tbl)
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
f.car = function(tbl)
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
f.head = f.car

--- Access the "tail" of a list
-- @function cdr
-- @tparam table tbl The list to be accessed
-- @treturn table Returns all but the first element in the list.
f.cdr = function(tbl)
  assert(type(tbl) == "table", "cdr expects tbl to be a table, but received a " .. type(tbl))
  return { unpack(tbl, 2) }
end
f.rest = f.cdr

--- Reverses an iterable
-- @function reverse
-- @param obj string or table
-- @return The reverse string or table
f.reverse = function(obj)
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
f.nth = function(iterable, begin, fin)
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
f.foldr = function(functor, tbl, val)
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
f.set = function(tbl)
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
f.ktov = function(tbl)
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

f.exclude = function(ex_tbl, tbl)
  local r = {}
  for _, v in ipairs(tbl) do
    if not f.inarray(ex_tbl, v) then
      r[#r + 1] = v
    end
  end
  return r
end

--- Maths
-- @section maths

f.shift = {}

-- Backported to Lua 5.1, introduced in 5.2, present in 5.3
-- This library gives us everything we need.
-- If not available, fall back to a slower Lua-only version
if _VERSION ~= "Lua 5.2" and _VERSION ~= "Lua 5.3" then
  bit32 = {}

  bit32.to_bit = function(x)
    
  end
  
  bit32.xor = function(a, b)
    local r = 0
    for i = 0, 31 do
      local x = a / 2 + b / 2
      if x ~= math.floor(x) then
        r = r + 2^i
      end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
    end
    return r
  end
  
  bit32.bor = function(a, b)
    local p,c=1,0
    while a+b>0 do
        local ra,rb=a%2,b%2
        if ra+rb>0 then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    return c
  end
  
  bit32.band = function(a, b)
    return ((a+b) - bit32.bxor(a,b))/2
  end

  bit32.rshift = function(a, b)
    return math.floor(x / 2 ^ by)
  end
  
  bit32.lshift = function(a, b)
    return x * 2 ^ by
  end
else
  bit32 = require "bit32"
end

f.base64 = {}
do
  local baseChars = {[0] = 'A', 'B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','-','_'}

  --- Base64 Encode
  -- @function base64.encode
  -- @tparam string str
  -- @treturn string Base64 encoded string
  f.base64.encode = function(str)
    if #str == 0 then
      return ""
    else
      local pad = 2 - ((#str-1) % 3)
   str = (str..string.rep('\0', pad)):gsub("...", function(cs)
      local a, b, c = string.byte(cs, 1, 3)
      return baseChars[bit32.rshift(a, 2)] ..
        baseChars[bit32.bor(bit32.lshift(bit32.band(a, 3), 4), bit32.rshift(b, 4))] ..
        baseChars[bit32.bor(bit32.lshift(bit32.band(b, 15), 2), bit32.rshift(c, 6))] ..
        baseChars[bit32.band(c, 63)]
   end)
   return str:sub(1, #str-pad) .. string.rep('=', pad)
    end
  end

  --- Base64 Decode
  -- TODO
  -- @function base64.decode
  -- @tparam string str
  -- @treturn string Decoded string
  f.base64.decode = function(str)
    if #str == 0 then
      return ""
    else
      error("Not Yet Implemented")
    end
  end
end

--- Wraps math.random, unless x is a table, in which case it gives a
-- random item from that table.
-- @function random
-- @param[opt] x
-- @param[opt] y
-- @return object
f.random = {}
setmetatable(f.random, {
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
f.random.weighted = function(tbl)
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
f.clamp = function(x, n, y)
  local t = {x, n, y}
  table.sort(t)
  return t[2]
end

--- Round a number to a certain number of places
-- @function round
-- @tparam number num The number to round
-- @tparam number depth The number of decimal places to round to
-- @treturn number The rounded number is returned
f.round = function(num, depth)
  depth = depth or 2
  return tonumber(string.format("%." .. tostring(depth) .. "f", num))
end

--- Addition operator
-- @function add
-- @tparam number a
-- @tparam number b
-- @treturn number Return a + b
f.add = function(a,b) return a + b end

--- Subtraction operator
-- @function sub
-- @tparam number a
-- @tparam number b
-- @treturn number Return a - b
f.sub = function(a, b) return a - b end

--- Multiplication operator
-- @function mul
-- @tparam number a
-- @tparam number b
-- @treturn number Return a * b
f.mul = function(a, b) return a * b end

-- We want div(a, b) and div.int(a, b) for integer division.
f.div = {}
setmetatable(f.div,
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
f.div.int = function(a, b) return math.floor(a/b) end

--- Operators
-- @section operators

--- Greater Than operator
-- @function gt
-- @param a
-- @param b
-- @treturn boolean
f.gt = function(a,b) return a > b end

--- Great Than or Equal operator
-- @function gte
-- @param a
-- @param b
-- @treturn boolean
f.gte = function(a,b) return a >= b end

--- Less Than operator
-- @function lt
-- @param a
-- @param b
-- @treturn boolean
f.lt = function(a,b) return a < b end

--- Less Than or Equal operator
-- @function lte
-- @param a
-- @param b
-- @treturn boolean
f.lte = function(a,b) return a <= b end

--- Not Equal operator
-- @function ne
-- @param a
-- @param b
-- @treturn boolean
f.ne = function(a,b) return a ~= b end

--- Unary operator
-- @function unary
-- @param a
-- @return Returns -a
f.unary = function(a) return -a end

--- Powerto operator
-- @function pow
-- @param a
-- @param b
-- @return Returns a^b
f.pow = function(a, b) return a^b end

--- Or operator
-- @function xor
-- @param a
-- @param b
-- @return Returns a or b
f.xor = function(a, b) return a or b end

--- And operator
-- @function xnd
-- @param a
-- @param b
-- @return Returns a and b
f.xnd = function(a, b) return a and b end

--- Not operator
-- @function xnt
-- @param a
-- @return Returns not a
f.xnt = function(a) return not a end

--- Abs operator
-- @function abs
-- @tparam number a
-- @treturn number Absolute value of a
f.abs = {}
setmetatable(f.abs,
    {
      __call = function(self, a) return math.abs(a) end
    })

--- abs.floor operator
-- @function abs.floor
-- @tparam number a
-- @treturn number Absolute value of a, run through math.floor
f.abs.floor = function(a)
  return math.floor(math.abs(a))
end

--- Mod Operator
-- @function mod
-- @param a
-- @param b
-- @treturn number Returns a % b
f.mod = {}
setmetatable(f.mod,
    {
      __call = function(self, a, b) return a % b end
    })

--- Mod floor Operator
-- @function mod
-- @param a
-- @param b
-- @treturn number Returns math.floor(a % b)
f.mod.floor = function(a, b)
  return math.floor(a % b)
end


--- Matrix
-- @section matrix

-- TODO
f.matrix = {}

--- matrix.new
-- @function matrix.new
-- @tparam number column
-- @tparam number row
-- @tparam[opt] number default
-- @treturn table A matrix with the given size, filled either with default or 0
f.matrix.new = function(column, row, default)
  assert(type(column) == "number")
  assert(type(row) == "number")
  if default == nil then default = 0 end

  local ret = {}

  -- Build the matrix
  for x = 0, row do
    ret[x] = {}
    for y = 0, column do
      ret[x][y] = default
    end
  end

  return ret
end

--- matrix.add
-- @function matrix.add
-- @tparam table matrix_a
-- @tparam table matrix_b
-- @treturn table Return a matrix from adding two matrices of the same size
f.matrix.add = function(matrix_a, matrix_b)
  assert(type(matrix_a) == "table")
  assert(type(matrix_b) == "table")
  assert(#matrix_a == #matrix_b, "Matrixes are not of the same size.")
  for i = 0, #matrix_a do
    assert(#matrix_a[i] == #matrix_b[i], "Matrix rows are not of the same size.")
  end

  local ret = {}
  for x = 0, #matrix_a do
    ret[x] = {}
    for y = 0, #matrix_a[x] do
      ret[x][y] = matrix_a[x][y] + matrix_b[x][y]
    end
  end
  return ret
end

--- matrix.sub
-- @function matrix.sub
-- @tparam table matrix_a
-- @tparam table matrix_b
-- @treturn table Return a matrix from subtracting two matrices of the same size
f.matrix.sub = function(matrix_a, matrix_b)
  assert(type(matrix_a) == "table")
  assert(type(matrix_b) == "table")
  assert(#matrix_a == #matrix_b, "Matrixes are not of the same size.")
  for i = 0, #matrix_a do
    assert(#matrix_a[i] == #matrix_b[i], "Matrix rows are not of the same size.")
  end

  local ret = {}
  for x = 0, #matrix_a do
    ret[x] = {}
    for y = 0, #matrix_a[x] do
      ret[x][y] = matrix_a[x][y] - matrix_b[x][y]
    end
  end
  return ret
end

--- matrix.mul
-- @function matrix.mul
-- @tparam table matrix_a
-- @tparam table matrix_b
-- @treturn table Return a matrix from multiplying two matrices of the same size
f.matrix.mul = function(matrix_a, matrix_b)
  assert(type(matrix_a) == "table")
  assert(type(matrix_b) == "table")
  assert(#matrix_a == #matrix_b, "Matrixes are not of the same size.")
  for i = 0, #matrix_a do
    assert(#matrix_a[i] == #matrix_b[i], "Matrix rows are not of the same size.")
  end

  local ret = {}
  for x = 0, #matrix_a do
    ret[x] = {}
    for y = 0, #matrix_a[x] do
      ret[x][y] = matrix_a[x][y] * matrix_b[x][y]
    end
  end
  return ret
end

--- matrix.div
-- @function matrix.div
-- @tparam table matrix_a
-- @tparam table matrix_b
-- @treturn table Return a matrix from dividing two matrices of the same size
f.matrix.div = {}
setmetatable(f.matrix.div,
    {
      __call = function(matrix_a, matrix_b)
  assert(type(matrix_a) == "table")
  assert(type(matrix_b) == "table")
  assert(#matrix_a == #matrix_b, "Matrixes are not of the same size.")
  for i = 0, #matrix_a do
    assert(#matrix_a[i] == #matrix_b[i], "Matrix rows are not of the same size.")
  end

  local ret = {}
  for x = 0, #matrix_a do
    ret[x] = {}
    for y = 0, #matrix_a[x] do
      ret[x][y] = matrix_a[x][y] / matrix_b[x][y]
    end
  end
  return ret
end
    })

--- matrix.div.int
-- @function matrix.div.int
-- @tparam table matrix_a
-- @tparam table matrix_b
-- @treturn table Return a matrix from dividing and flooring two matrices of the same size
f.matrix.div.int = function(matrix_a, matrix_b)
  assert(type(matrix_a) == "table")
  assert(type(matrix_b) == "table")
  assert(#matrix_a == #matrix_b, "Matrixes are not of the same size.")
  for i = 0, #matrix_a do
    assert(#matrix_a[i] == #matrix_b[i], "Matrix rows are not of the same size.")
  end

  local ret = {}
  for x = 0, #matrix_a do
    ret[x] = {}
    for y = 0, #matrix_a[x] do
      ret[x][y] = math.floor(matrix_a[x][y] / matrix_b[x][y])
    end
  end
  return ret
end

--- matrix.element
-- @function matrix.element
-- @tparam table mtx
-- @tparam number column
-- @tparam number row
-- @return Returns given element from the given matrix. 
f.matrix.element = function(mtx, column, row)
  assert(type(mtx) == "table")
  assert(type(column) == "number")
  assert(type(row) == "number")
  return mtx[row][column]
end

--- matrix.row
-- @function matrix.row
-- @tparam table mtx
-- @tparam number row
-- @treturn table Returns a row from the given matrix
f.matrix.row = function(mtx, row)
  assert(type(mtx) == "table")
  assert(type(row) == "number")
  return mtx[row]
end

--- matrix.column
-- @function matrix.column
-- @tparam table mtx
-- @tparam number row
-- @treturn table Returns a column from the given matrix
f.matrix.column = function(mtx, column)
  assert(type(mtx) == "table")
  assert(type(column) == "number")
  local ret = {}
  for x = 0, #mtx do
    ret[#ret + 1] = mtx[x][column]
  end
  return ret
end

-- matrix.det
-- matrix.invert
-- matrix.sqrt
-- matrix.avg
-- matrix.root
-- matrix.random
-- matrix.type
-- matrix.transpose
-- matrix.range
-- matrix.concat
-- matrix.rotl
-- matrix.rotr
-- matrix.tostring
-- matrix.print
-- matrix.iter

--- Ports
-- @section ports

f.port = {}

--- Override print and io.write with port:write for a given port
-- @function port.with_output
-- @param port A port-like object
-- @tparam function functor
-- @return Returns functor's return value.
f.port.with_output = function(port, functor)
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
f.port.with_input = function(port, functor)
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
f.port.make_input = function(read_func, close_func)
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
f.port.make_output = function(write_func, read_func, close_func)
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
f.port.from_string = function(str, functor)
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
f.port.iter = function(port, n, data)
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
f.eq = function(a, b)
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
f.inarray = function(tbl, v)
  for _, val in ipairs(tbl) do
    if v == val then return true end
  end
  return false
end

--- Predicate to test string type
-- @function isstring
-- @param x The object to test if is a string
-- @treturn boolean
f.isstring = function(x)
  return type(x) == "string"
end

--- Predicate to test number type
-- @function isnumber
-- @param x The object to test if is a number
-- @treturn boolean
f.isnumber = function(x)
  return type(x) == "number"
end

--- Returns true or false, given any object, if it is a positive number
-- @function ispositive
-- @param x
-- @treturn boolean
f.ispositive = function(x)
  if f.isnumber(x) and x > 0 then
    return true
  else
    return false
  end
end

--- Returns true or false, given any object, if it is a negative number
-- @function isnegative
-- @param x
-- @treturn boolean
f.isnegative = function(x)
  if f.isnumber(x) and x < 0 then
    return true
  else
    return false
  end
end

--- Returns true or false, given any object, if it is 0
-- @function iszero
-- @param x
-- @treturn boolean
f.iszero = function(x)
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
f.isfunction = function(x)
  return type(x) == "function"
end

--- Predicate to test boolean type
-- @function isboolean
-- @param x The object to test if is a boolean
-- @treturn boolean
f.isboolean = function(x)
  return type(x) == "boolean"
end

--- Predicate to test nil type
-- @function isnil
-- @param x The object to test if is a nil
-- @treturn boolean
f.isnil = function(x)
  return x == nil
end

--- Predicate to test table type
-- @function istable
-- @param x The object to test if is a table
-- @treturn boolean
f.istable = function(x)
  return type(x) == "table"
end

--- Predicate to test thread type
-- @function isthread
-- @param x The object to test if is a thread
-- @treturn boolean
f.isthread = function(x)
  return type(x) == "thread"
end

--- Predicate to test userdata type
-- @function isuserdata
-- @param x The object to test if is a userdata
-- @treturn boolean
f.isuserdata = function(x)
  return type(x) == "userdata"
end

--- Predicate to test file type
-- @function isfile
-- @param x The object to test if is a file
-- @treturn boolean
f.isfile = function(x)
  return io.type(x) == "file"
end

-- Because we have so many functions that rely on math.random,
-- we seed it upon require.
math.randomseed(os.time())

--- Use With Caution
-- @section caution

do
  local cache = {}

  --- Pollute the global namespace with f.lua's functions.
  -- @function pollute
  -- @treturn nil No return value.
  f.pollute = function()
    for k, v in pairs(f) do
      if _G[k] ~= nil then cache[k] = _G[k] end
      _G[k] = v
    end
  end

  --- Undo pollution of the global namespace by f.pollute.
  -- @function unpollute
  -- @treturn nil No return value.
  f.unpollute = function()
    for k, v in pairs(f) do
      if cache[k] ~= nil then
        _G[k] = cache[k]
      else
        _G[k] = nil
      end
    end
  end
end

--- Add a vendor path to Lua
-- @function vend
-- @tparam string vendor
-- @treturn nil
f.vend = function(vendor)
  local vendor = vendor or "vendor"
  local version = _VERSION:match("%d+%.%d+")
  package.path = vendor .. '/share/lua/' .. version .. '/?.lua;' .. vendor .. '/share/lua/' .. version .. '/?/init.lua;' .. package.path
  package.cpath = vendor .. '/lib/lua/' .. version .. '/?.so;' .. package.cpath
end

return f
