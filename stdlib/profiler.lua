PROFILER_ENABLED = true
profilerShowing = 'update'

local easable = require('stdlib.easable')

local text = BitmapText()
local quad = Quad()

oat.useProfiler = true

if PROFILER_ENABLED then
  local max = easable(0)

  local function draw()
    if not profilerInfo[profilerShowing] then return end

    quad:diffuse(0.2, 1, 0.2, 0.9)
    quad:align(0, 0)
    text:align(0, 0)
    text:shadowlength(0)

    table.sort(profilerInfo[profilerShowing], function(a, b) return a.t > b.t end)
    local maxt = 0
    for i, e in ipairs(profilerInfo[profilerShowing]) do
      maxt = math.max(maxt, e.t)
      quad:zoomto(e.t / max.a * sw * 0.4, 24)
      quad:xy(0, i * 24)
      quad:Draw()

      text:settext((math.floor(e.t * 100000) / 100) .. 'ms')
      text:xy(0, i * 24)
      text:zoom(0.3)
      text:diffuse(0.2, 0.2, 0.2, 0.9)
      text:Draw()
      text:settext(e.src)
      text:xy(0, i * 24 + 12)
      text:zoom(0.2)
      text:diffuse(0.1, 0.1, 0.1, 0.9)
      text:Draw()
    end

    max:set(maxt)

    text:diffuse(1, 1, 1, 1)
    text:xy(0, 0)
    text:zoom(0.5)
    text:shadowlength(3)
    text:settext('Profiler - ' .. profilerShowing)
    text:Draw()
  end

  function uranium.update(dt)
    max(dt * 12)
    draw()
  end
end