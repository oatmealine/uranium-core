require('stdlib.util')

---@class easable
---@field public a number @the eased value
---@field public toa number @the target, uneased value
local eas = {}

---@param new number @New value to ease to
---@return void
function eas:set(new)
  self.toa = new
end

---@param new number @New value
---@return void
function eas:reset(new)
  self.toa = new
  self.a = new
end

---@param new number @How much to add to current value to ease to
---@return void
function eas:add(new)
  self.toa = self.toa + new
end

local easmeta = {}

easmeta.__index = eas
easmeta.__name = 'easable'

function easmeta.__add(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) + ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__sub(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) - ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__mul(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) * ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__div(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) / ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__mod(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) % ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__eq(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) == ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__lt(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) < ((type(b) == 'table' and b.a) and b.a or b)
end
function easmeta.__le(a, b)
  return ((type(a) == 'table' and a.a) and a.a or a) <= ((type(b) == 'table' and b.a) and b.a or b)
end

function easmeta:__call(dt)
  self.a = mix(self.a, self.toa, dt)
end
function easmeta:__tostring()
  return tostring(self.a)
end
function easmeta:__unm(self)
  return -self.a
end

---@param default number
---@return easable
return function(default)
  default = default or 0
  return setmetatable({a = default, toa = default}, easmeta)
end