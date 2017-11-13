local load = loadstring or load
local unpack = unpack or table.unpack

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
  local first = true
  local ret = {}
  for ix, v in pairs(tbl) do
    if first then
      first = false
      if ix == nil then
        return {}
      end
    else
      if type(ix) == "number" then
        ret[#ret + 1] = v
      else
        ret[ix] = v
      end
    end
  end
  return ret
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
  assert(type(functor) == "function", "apply expects functor to be a function")
  return functor(unpack(args))
end

local map
map = function(functor, args)
  assert(type(args) == "table", "map expects args to be a table, but received a " .. type(args))
  assert(type(functor) == "function", "map expects functor to be a function")
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

return {
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
  curry = curry,
  eq = eq,
  recur = recur,
  isstring = isstring,
  isnumber = isnumber,
  isfunction = isfunction,
  isboolean = isboolean,
  isnil = isnil,
  istable = istable,
  isuserdata = isuserdata,
  isfile = isfile,
}
