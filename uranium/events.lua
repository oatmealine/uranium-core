useProfiler = false
profilerInfo = {}

local uraniumFunc = {}

local debugCache = {}
function uraniumFunc:call(event, ...)
  if self._callbacks[event] then
    profilerInfo[event] = {}
    for _, callback in ipairs(self._callbacks[event]) do
      local start = os.clock()
      local res = callback(unpack(arg))
      local dur = os.clock() - start

      if oat.useProfiler then
        if not debugCache[callback] then
          debugCache[callback] = debug.getinfo(callback, 'Sl') -- cached cus debug.getinfo is EXPENSIVE
        end
        local finfo = debugCache[callback]

        table.insert(profilerInfo[event], {
          src = finfo.short_src .. ':' .. finfo.linedefined,
          t = dur
        })
      end

      if res ~= nil then return res end
    end
  end
end

local uraniumMeta = {}

function uraniumMeta:__newindex(key, value)
  if self._callbacks[key] then
    table.insert(self._callbacks[key], value)
  else
    self._callbacks[key] = {value}
  end
end

uraniumMeta.__index = uraniumFunc

uranium = setmetatable({_callbacks = {}}, uraniumMeta)