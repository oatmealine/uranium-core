local self = {}

self.inputs = { -- -1 for not pressed, time for time of press
  Left = -1,
  Down = -1,
  Up = -1,
  Right = -1
}
self.rawInputs = {
  Left = -1,
  Down = -1,
  Up = -1,
  Right = -1
}

self.directions = {
  Left = {-1, 0},
  Down = {0, 1},
  Up = {0, -1},
  Right = {1, 0}
}

function uranium.init()
  for pn = 1, 2 do
    for i,j in ipairs({'Left', 'Down', 'Up', 'Right'}) do
      local i = i -- lua scope funnies
      local j = j
  
      _main:addcommand('StepP' .. pn .. j .. 'PressMessage', function()
        self.rawInputs[j] = t
        if uranium:call('press', j) then return end
        self.inputs[j] = t
      end)
      _main:addcommand('StepP' .. pn .. j .. 'LiftMessage', function()
        if uranium:call('release', j) then return end
        self.inputs[j] = -1
        self.rawInputs[j] = -1
      end)
    end
  end
end

return self