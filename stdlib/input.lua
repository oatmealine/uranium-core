local self = {}

---@enum inputType
self.inputType = {
  Left = 0,
  Down = 1,
  Up = 2,
  Right = 3,
  Start = 4,
  Select = 5,
  Back = 6,
  Coin = 7,
  Operator = 8,
  UpLeft = 9,
  UpRight = 10,
  MenuLeft = 11,
  MenuDown = 12,
  MenuUp = 13,
  MenuRight = 14,
  MenuStart = 15,
  ActionLeft = 16,
  ActionDown = 17,
  ActionUp = 18,
  ActionRight = 19,
  Action1 = 20,
  Action2 = 21,
  Action3 = 22,
  Action4 = 23,
  Action5 = 24,
  Action6 = 25,
  Action7 = 26,
  Action8 = 27
}

---@type table<inputType, number>
--- -1 for not pressed, time for time of press
self.inputs = {}
---@type table<inputType, number>
self.rawInputs = {}

for _, v in pairs(self.inputType) do
  self.inputs[v] = -1
  self.rawInputs[v] = -1
end

self.directions = {
  [self.inputType.Left] = {-1, 0},
  [self.inputType.Down] = {0, 1},
  [self.inputType.Up] = {0, -1},
  [self.inputType.Right] = {1, 0}
}

-- Mappings for the default keybinds for these keys; recommended to put alongside the in-game representation in UIs
self.keyboardEquivalent = {
  [self.inputType.Left] = 'L',
  [self.inputType.Down] = 'D',
  [self.inputType.Up] = 'U',
  [self.inputType.Right] = 'R',
  [self.inputType.Start] = 'Enter',
  [self.inputType.Select] = 'Shift',
  [self.inputType.Action1] = '1',
  [self.inputType.Action2] = '2',
  [self.inputType.Action3] = '3',
  [self.inputType.Action4] = '4',
  [self.inputType.Action5] = '5',
  [self.inputType.Action6] = '6',
  [self.inputType.Action7] = '7',
  [self.inputType.Action8] = '8',
  [self.inputType.Coin] = 'F1',
  [self.inputType.Back] = 'Esc'
}

---@param i inputType
---@return string | nil
function self.getInputName(i)
  for k, v in pairs(self.inputType) do
    if v == i then return k end
  end
  return nil
end

---@param i string
---@return number
function self.getInput(i)
  return self.inputs[self.inputType[i]]
end

---@param i string
---@return boolean
function self.isDown(i)
  return self.getInput(i) ~= -1
end

function uranium.init()
  for pn = 1, 2 do
    for j, v in pairs(self.inputType) do
      local j = j -- lua scope funnies
      local v = v

      _main:addcommand('StepP' .. pn .. j .. 'PressMessage', function()
        self.rawInputs[v] = t
        if uranium:call('press', v) then return end
        self.inputs[v] = t
      end)
      _main:addcommand('StepP' .. pn .. j .. 'LiftMessage', function()
        if uranium:call('release', v) then return end
        self.inputs[v] = -1
        self.rawInputs[v] = -1
      end)
    end
  end
end

return self