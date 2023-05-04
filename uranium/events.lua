useProfiler = false

---@class ProfilerInfo
---@field public t number
---@field public src string

---@type table<string, ProfilerInfo>
profilerInfo = {}

local callbacks = {}

local debugCache = {}

---@param event string
---@param ... any
---@return any
--- Call a defined callback.
function uranium.call(event, ...)
  if callbacks[event] then
    profilerInfo[event] = {}
    for _, callback in ipairs(callbacks[event]) do
      local start = os.clock()
      local res = callback(unpack(arg))
      local dur = os.clock() - start

      if useProfiler then
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

---@param event string
---@param f function
--- Register a callback handler.
function uranium.on(event, f)
  if not callbacks[event] then
    callbacks[event] = {}
  end
  table.insert(callbacks[event], f)
end