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
    return nil
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

local let
let = function(values, functor)
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
  if unpack == nil then
    return table.unpack(ret)
  else
    return unpack(ret)
  end
end

local cond
cond = function(condlist)
  assert(type(condlist) == "table")
  assert(condlist[1])
  for k, v in pairs(condlist) do
    assert(type(v) == "table")
    assert(#v == 2)
    assert(type(k) == "number")
  end
  
  for i=1, #condlist do
    if condlist[i][1] == true then
      return condlist[i][2]
    end
  end
  return nil
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
  cond = cond
}
