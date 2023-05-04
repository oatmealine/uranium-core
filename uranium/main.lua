local function copy(src)
  local dest = {}
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

oat = _G.oat
type = _G.type
print = _G.print
pairs = _G.pairs
ipairs = _G.ipairs
unpack = _G.unpack
tonumber = _G.tonumber
tostring = _G.tostring
math = copy(_G.math)
table = copy(_G.table)
string = copy(_G.string)

scx = SCREEN_CENTER_X
scy = SCREEN_CENTER_Y
sw = SCREEN_WIDTH
sh = SCREEN_HEIGHT
dw = DISPLAY:GetDisplayWidth()
dh = DISPLAY:GetDisplayHeight()

local resetOnFrameStartCfg = false
local resetOnFrameStartActors = {}

--- The Uranium Template table! All template-related functionality is stored here.
uranium = {}

require 'uranium.events'

local hasExited = false
local function exit()
  if hasExited then return end
  hasExited = true
  uranium.call('exit')
  -- good templates clean up after themselves
  uranium = nil
  _G.oat = nil
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

local luaobj

local function onCommand(self)
  oat._actorsInitialized = true
  oat._actorsInitializing = false
  local resetOnFrameStartActors_ = {}
  for k,v in pairs(resetOnFrameStartActors) do
    resetOnFrameStartActors_[k.__raw] = v
  end
  resetOnFrameStartActors = resetOnFrameStartActors_
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

function resetOnFrameStart(bool)
  resetOnFrameStartCfg = bool
end

function resetActorOnFrameStart(actor, bool)
  if bool == nil then bool = not resetOnFrameStartCfg end
  resetOnFrameStartActors[actor.__raw or actor] = bool
end

require 'uranium.actors'

local lastt = GAMESTATE:GetSongTime()
local function screenReadyCommand(self)
  hideThemeActors()
  self:hidden(0)
  oat._actor = {}

  oat._actorQueue = {}
  oat._actorAssociationQueue = {}

  oat._actorTree = {}
  oat._currentPath = nil
  oat._pastPaths = {}
  oat._currentActor = nil

  collectgarbage()

  local errored = false
  local firstrun = true
  local playersLoaded = false
  self:addcommand('Update', function()
    if errored then
      return 0
    end
    errored = true

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

    for _, q in ipairs(oat._globalQueue) do
      local enabled = resetOnFrameStartCfg

      local actor = q[1]
      local v = q[2]

      local pref = resetOnFrameStartActors[actor]
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

if not pcall(function() oat._release = require('uranium.release') end) then
  oat._release = require('uranium.release_blank')
end

local success, result = pcall(function()
  require('main')
end)

if success then
  luaobj = result

  print('---')

  oat._actorsInitializing = true
  oat._transformQueueToTree()
  --Trace(fullDump(oat._actorTree))
  oat._currentPath = oat._actorTree

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