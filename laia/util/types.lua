require 'laia.util.string'
laia = laia or {}

local __toboolean_table = {
  [true]    = true,
  [1]       = true,
  ['true']  = true,
  ['TRUE']  = true,
  ['T']     = true,
  ['1']     = true,
  [false]    = false,
  [0]       = false,
  ['false'] = false,
  ['FALSE'] = false,
  ['F']     = false,
  ['0']     = false
}

-- Check whether a variable's value is a valid boolean type or not.
function laia.isboolean(x)
  return (x == true or x == false)
end

-- Check whether a variable's value is a valid integer number or not.
function laia.isint(x)
  return (type(x) == 'number' and x == math.floor(x))
end

-- Convert a variable value to a boolean, if the value is not a valid boolean
-- returns nil and an error message.
function laia.toboolean(x)
  return __toboolean_table[tostring(x)], ('value %q is not a boolean'):format(tostring(x))
end

-- Convert a variable value to an integer, if the value is not a valid integer
-- returns nil and an error message.
function laia.toint(x)
  local xn = tonumber(x)
  if laia.isint(xn) then return xn
  else return nil, ('value %q is not an integer'):format(tostring(x)) end
end

-- Given a string that represents a list of NUMBERS separated by commas,
-- returns a table with the list items.
function laia.tolistnum(x)
  local sx = laia.strsplit(x, '[^,]+')
  local rx = {}
  for _, v in ipairs(sx) do
    local v2 = tonumber(v)
    if v2 == nil then return nil, ('value %q is not a number'):format(tostring(v)) end
    table.insert(rx, v2)
  end
  return rx
end

-- Given a string that represents a list of INTEGERS separated by commas,
-- returns a table with the list items.
function laia.tolistint(x)
  local sx = laia.strsplit(x, '[^,]+')
  local rx = {}
  for _, v in ipairs(sx) do
    local v2 = laia.toint(v)
    if v2 == nil then
      return nil, ('value %q is not an integer'):format(tostring(v))
    end
    table.insert(rx, v2)
  end
  return rx
end
