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
        return nil
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
  return assert(load("return function " .. s .. " end"))()
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
