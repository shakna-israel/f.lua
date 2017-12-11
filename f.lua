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

local elif
elif = function(predicate, a, b)
  assert(type(predicate) == "boolean", "elif expects predicate to be boolean, but received " .. type(predicate))
  if predicate then
    return a
  else
    return b
  end
end

local cons
cons = function(val, tbl)
  if tbl == nil then
    tbl = {}
  end
  assert(type(tbl) == "table", "cons expects tbl to be a table, but received a " .. type(tbl))
  table.insert(tbl, 1, val)
  return tbl
end

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

local cdr
cdr = function(tbl)
  assert(type(tbl) == "table", "cdr expects tbl to be a table, but received a " .. type(tbl))
  return { unpack(tbl, 2) }
end

-- String Lambda!
-- e.g. f.fn("(x, y) print(x, y)")(2, 3)
local fn
fn = function(s)
  return assert(load("return function " .. tostring(s) .. " end"), "fn was unable to build a valid function from: " .. tostring(s))()
end

local let
let = function(values, functor)
  assert(type(functor) == "function")
  -- Preperations
  backups = {}
  for k, v in pairs(values) do
    if _G[k] ~= nil then
      backups[k] = _G[k]
      _G[k] = v
    else
      _G[k] = v
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

local apply
apply = function(functor, args)
  assert(type(args) == "table", "apply expects args to be a table, but received " .. type(args))
  assert(type(functor) == "function" or type(getmetatable(functor).__call) == "function", "apply expects functor to be a function")
  return functor(unpack(args))
end

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

local curry
curry = function(a, b)
  assert(type(a) == "function", "curry expects a to be a function, but received a " .. type(a))
  assert(type(b) == "function", "curry expects b to be a function, but received a " .. type(b))
  return function(...)
    return a(b(...))
  end
end

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

local recur
recur = function()
  return debug.getinfo(2, "f").func
end

local with
with = function(filepath, permissions, functor)
  assert(type(filepath) == "string")
  assert(type(permissions) == "string")
  assert(type(functor) == "function")  
  local file = io.open(filepath, permissions)
  ret = {functor(file)}
  if file then file:close() end
  return unpack(ret)
end

-- Coroutines

local co = {}
setmetatable(co, {
  __call = function(functor)
    return coroutine.wrap(functor)
  end
})

co.c = function(functor)
  return coroutine.create(functor)
end

co.t = function(thread)
  assert(type(thread) == "thread", "co.t expects a thread, but received a " .. type(thread))
  if coroutine.status(thread) == "suspended" then
    return coroutine.resume(thread)
  elseif coroutine.status(thread) == "dead" then
    return nil
  end
end

co.r = function()
  return coroutine.running()
end

-- Predicates

local isstring
isstring = function(x)
  return type(x) == "string"
end

local isnumber
isnumber = function(x)
  return type(x) == "number"
end

local isfunction
isfunction = function(x)
  return type(x) == "function"
end

local isboolean
isboolean = function(x)
  return type(x) == "boolean"
end

local isnil
isnil = function(x)
  return x == nil
end

local istable
istable = function(x)
  return type(x) == "table"
end

local isthread
isthread = function(x)
  return type(x) == "thread"
end

local isuserdata
isuserdata = function(x)
  return type(x) == "userdata"
end

local isfile
isfile = function(x)
  return io.type(x) == "file"
end

-- Operators
local add = function(a,b) return a + b end
local sub = function(a, b) return a - b end
local mul = function(a, b) return a * b end

-- We want div(a, b) and div.int(a, b) for integer division.
local div = {}
setmetatable(div,
    {
      __call = function(self, a, b) return a / b end
    })
div.int = function(a, b) return math.floor(a/b) end

local gt = function(a,b) return a > b end
local gte = function(a,b) return a >= b end
local lt = function(a,b) return a < b end
local lte = function(a,b) return a <= b end
local ne = function(a,b) return a ~= b end

return {
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
  ne = ne
}
