local elif
elif = function(predicate, a, b)
  assert(type(predicate) == "boolean")
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
  assert(type(tbl) == "table")
  table.insert(tbl, 1, val)
  return tbl
end

local car
car = function(tbl)
  assert(type(tbl) == "table")
  local ix, v = next(tbl)
  if ix == 0 or ix == 1 then
    return v
  elseif ix == nil then
    return {}
  else
    return ix, v
  end
end

local cdr
cdr = function(tbl)
  assert(type(tbl) == "table")
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
  if loadstring == nil then
    return assert(load("return function " .. s .. " end"))()
  else
    return assert(loadstring("return function " .. s .. " end"))()
  end
end

-- http://lua-users.org/wiki/CopyTable
-- DeepCopy's a table
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local let
let = function(values, functor)
  env = deepcopy(_G)
  for k, v in pairs(values) do
    env[k] = v
  end
  setfenv(functor, env)
  return pcall(functor)
end

return {
  elif = elif,
  cons = cons,
  car = car,
  head = car,
  cdr = cdr,
  rest = cdr,
  fn = fn
}
