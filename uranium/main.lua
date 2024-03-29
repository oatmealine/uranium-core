require 'uranium.constants'
require 'uranium.events'
local actors = require 'uranium.actors'
local config = require 'uranium.config'

local hasExited = false
local function exit()
  if hasExited then return end
  hasExited = true
  uranium.call('exit')
  -- good templates clean up after themselves
  uranium = nil
  _G.oat = nil
  ---@diagnostic disable-next-line: assign-type-mismatch
  oat = nil
  _main:hidden(1)
  collectgarbage()
end

function backToSongWheel(message)
  if message then
    SCREENMAN:SystemMessage(message)
    print(message)
  end
  exit()
  GAMESTATE:FinishSong()
  -- disable update_command
  _main:hidden(1)
end

local function onCommand(self)
  actors._actorsInitialized = true
  actors._actorsInitializing = false
  local resetOnFrameStartActors_ = {}
  for k,v in pairs(config.resetActorOnFrameStart) do
    resetOnFrameStartActors_[k.__raw] = v
  end
  config.resetActorOnFrameStart = resetOnFrameStartActors_
  uranium.call('init')
end

-- runs once during ScreenReadyCommand, before the user code is loaded
-- hides various actors that are placed by the theme
local function hideThemeActors()
  for _, element in ipairs {
    'Overlay', 'Underlay',
    'ScoreP1', 'ScoreP2',
    'LifeP1', 'LifeP2',
    'PlayerOptionsP1', 'PlayerOptionsP2', 'SongOptions',
    'LifeFrame', 'ScoreFrame',
    'DifficultyP1', 'DifficultyP2',
    'BPMDisplay',
    'MemoryCardDisplayP1', 'MemoryCardDisplayP2'
  } do
    local child = SCREENMAN(element)
    if child then child:hidden(1) end
  end
end

GAMESTATE:ApplyModifiers('clearall')

local lastt = GAMESTATE:GetSongTime()
local function screenReadyCommand(self)
  actors.finalize()

  if config.hideThemeActors then
    hideThemeActors()
  end

  self:hidden(0)

  collectgarbage()

  local errored = false
  local firstrun = true
  local playersLoaded = false
  self:addcommand('Update', function()
    if errored then
      return 0
    end
    errored = true

    local P1, P2 = SCREENMAN('PlayerP1'), SCREENMAN('PlayerP2')
    if P1 and P2 then
      playersLoaded = true
    end
    if playersLoaded and not P1 and not P2 then -- sora exit hack
      exit()
    end

    t = os.clock()
    b = GAMESTATE:GetSongBeat()
    local dt = t - lastt
    lastt = t

    if firstrun then
      firstrun = false
      dt = 0
      self:GetChildren()[2]:hidden(1)
      uranium.call('ready')
    end

    drawfunctionArguments = {}

    for _, q in ipairs(actors._globalQueue) do
      local enabled = config.resetOnFrameStart

      local actor = q[1]
      local v = q[2]

      local pref = config.resetActorOnFrameStart[actor]
      if pref ~= nil then enabled = pref end

      if enabled then
        local func = actor[v[1]]
        if not func then
          -- uhmmm ??? hm. what do we do??
        else
          oat._patchFunction(func, actor)(unpack(v[2]))
        end
      end
    end

    uranium.call('preUpdate', dt)
    uranium.call('update', dt)
    uranium.call('postUpdate', dt)

    errored = false

    return 0
  end)
  self:luaeffect('Update')
end

---@class UraniumRelease
---@field branch string
---@field commit string
---@field version string
---@field name string
---@field prettyName string
---@field homeURL string

---@type UraniumRelease
uranium.release = {}

if not pcall(function() uranium.release = require('uranium.release') end) then
  uranium.release = require('uranium.release_blank')
end

local success, result = pcall(function()
  return require('main')
end)

if success then
  print('---')

  actors.prepareForActors()

  _main:addcommand('On', onCommand)
  _main:addcommand('Ready', screenReadyCommand)
  _main:addcommand('Off', exit)
  _main:addcommand('SaltyReset', exit)
  _main:addcommand('WindowFocus', function()
    uranium.call('focus', true)
  end)
  _main:addcommand('WindowFocusLost', function()
    uranium.call('focus', false)
  end)
  _main:queuecommand('Ready')
else
  Trace('got an error loading main.lua!')
  Trace(result)
  backToSongWheel('loading .lua file failed, check log for details')
  error('uranium: loading main.lua file failed:\n' .. result)
end