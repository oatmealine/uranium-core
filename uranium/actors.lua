local M = {}

M._actorsInitialized = false -- if true, no new actors can be created
M._actorsInitializing = false -- the above but a bit more explicit

local drawfunctionArguments = {}
local specialActorFrames = {} -- ones defined specifically; here for drawfunction jank

---@param frame ActorFrame
---@param func function
--- SetDrawFunction with special behavior to account for Uranium's actor loading scheme.
function setDrawFunction(frame, func)
  --if not frame.__raw then error('uranium: cannot set actorframe drawfunction during module loadtime! put this in uranium.init or actor:addcommand(\'Init\', ...)', 2) end
  if not frame.SetDrawFunction then error('uranium: expected an actorframe but got something that doesn\'t even bother to implement SetDrawFunction', 2) end
  if type(func) ~= 'function' then error('uranium: tried to set a drawfunction to a.. ' .. type(func) .. '?? the hell', 2) end
  frame:SetDrawFunction(function()
    for i = 1, frame:GetNumChildren() do
      local a = frame:GetChildAt(i - 1)
      if specialActorFrames[a] == false then
        a:Draw()
      end
    end
    local args = drawfunctionArguments[frame]
    if args then
      func(unpack(args))
    else
      func()
    end
  end)
end

---@param actor Actor
---@param shader RageShaderProgram
function setShader(actor, shader)
  if not shader.__raw then
    uranium.on('init', function() setShader(actor, shader) end)
  else
    actor:SetShader(shader.__raw)
  end
end

function setShaderfuck(shader)
  if not shader.__raw then
    uranium.on('init', function() setShaderfuck(shader) end)
  else
    DISPLAY:ShaderFuck(shader.__raw)
  end
end

function clearShaderfuck()
  DISPLAY:ClearShaderFuck()
end

oat._actorAssociationTable = {}

-- Gets every child of an ActorFrame. More accurate than :GetChildren()
---@param frame ActorFrame
---@return Actor[]
function getChildren(frame)
  local c = oat._actorAssociationTable[frame]
  if c then
    return c
  else
    error('uranium: actorframe doesn\'t exist (or isn\'t an actorframe)', 2)
  end
end

local patchedFunctions = {}
function oat._patchFunction(f, obj)
  if not patchedFunctions[f] then patchedFunctions[f] = {} end
  if not patchedFunctions[f][obj] then
    patchedFunctions[f][obj] = function(...)
      arg[1] = obj
      local results
      local status, result = pcall(function()
        -- doing it this way instead of returning because lua
        -- offers no way of grabbing everything BUT the first
        -- argument out of pcall
        results = {f(unpack(arg))}
      end)
      if not status then
        error(result, 2)
      else
        return unpack(results)
      end
    end
  end
  return patchedFunctions[f][obj]
end

M._globalQueue = {} -- for resetting

---@param actor Actor
--- Resets an actor to its initial state
function reset(actor)
  if not M._actorsInitialized then error('uranium: cannot reset an actor during initialization', 2) end
  for _, q in ipairs(M._globalQueue) do
    local queueActor = q[1]
    if queueActor == actor.__raw then
      local v = q[2]

      local func = queueActor[v[1]]
      if not func then
        -- uhmmm ??? hm. what do we do??
      else
        oat._patchFunction(func, queueActor)(unpack(v[2]))
      end
    end
  end
end
resetActor = reset

M._actorQueue = {}
M._actorAssociationQueue = {}

M._actorTree = {}
M._currentPath = nil
M._pastPaths = {}
M._currentActor = nil

local function findFirstActor(path)
  for i, v in ipairs(path) do
    if v.type or v.file then
      return v, i
    end
  end
end

local function findFirstActorFrame(path)
  for i, v in ipairs(path) do
    if not v.type and not v.file then
      return v, i
    end
  end
end

oat._actor = {}

local function nextActor()
  local new, idx = findFirstActor(M._currentPath)
  if not new then
    M._currentActor = nil
  else
    M._currentActor = new
    table.remove(M._currentPath, idx)
  end
end

function oat._actor.recurse(forceActor)
  local newFrame, idx = findFirstActorFrame(M._currentPath)
  local newActor = findFirstActor(M._currentPath)
  if newFrame and not (newActor and forceActor) then
    table.insert(M._pastPaths, M._currentPath)
    M._currentPath = M._currentPath[idx]
    table.remove(M._pastPaths[#M._pastPaths], idx)
    return true
  elseif newActor then
    table.insert(M._pastPaths, M._currentPath)
    return true
  else
    return false
  end
end

function oat._actor.recurseLast()
  return oat._actor.recurse(true)
end

function oat._actor.endRecurse()
  M._currentPath = table.remove(M._pastPaths, #M._pastPaths)
end

function oat._actor.cond()
  return M._currentActor ~= nil
end

function oat._actor.hasShader()
  return oat._actor.cond() and (M._currentActor.frag ~= nil or M._currentActor.vert ~= nil)
end

function oat._actor.noShader()
  nextActor()
  return oat._actor.cond() and not oat._actor.hasShader()
end

function oat._actor.type()
  return M._currentActor.type
end

function oat._actor.file()
  return M._currentActor.file
end

function oat._actor.frag()
  return M._currentActor.frag or 'nop.frag'
end

function oat._actor.vert()
  return M._currentActor.vert or 'nop.vert'
end

function oat._actor.font()
  return M._currentActor.font
end

function oat._actor.init(self)
  M._currentActor.init(self)
  self:removecommand('Init')
  M._currentActor = nil -- to prevent any weirdness
end

function oat._actor.initFrame(self)
  self:removecommand('Init')
  self:SetDrawFunction(function()
    for i = 1, self:GetNumChildren() do
      local a = self:GetChildAt(i - 1)
      if specialActorFrames[a] == false then
        a:Draw()
      end
    end
  end)

  if M._currentPath.init then
    M._currentPath.init(self)
    M._currentPath.init = nil
    specialActorFrames[self] = true
  else
    specialActorFrames[self] = false
  end
end

local actorMethodOverrides = {
  Draw = function(self, ...)
    drawfunctionArguments[self] = arg
    self.__raw:Draw()
  end
}

-- todo: probably make this more sane
local function createProxyActor(name)
  local queue = {}
  local initCommands = {}
  local lockedActor
  local queueRepresentation

  return setmetatable({}, {
    __index = function(self, key)
      if key == '__raw' then
        return lockedActor
      end
      if lockedActor then
        if actorMethodOverrides[key] then
          return actorMethodOverrides[key]
        else
          local val = lockedActor[key]
          if type(val) == 'function' then
            return oat._patchFunction(val, lockedActor)
          end
          return val
        end
      end
      if key == '__queue' then
        return queueRepresentation
      end
      if key == '__queueRepresentation' then
        return function(q)
          queueRepresentation = q
        end
      end
      if key == '__lock' then
        return function(actor)
          if lockedActor then return end
          for _, v in ipairs(queue) do
            local func = actor[v[1]]
            if not func then
              error(
                'uranium: error on \'' .. name .. '\' initialization on ' .. v[3].short_src .. ':' .. v[3].currentline .. ':\n' ..
                'you\'re calling a function \'' .. v[1] .. '\' on a ' .. name .. ' which doesn\'t exist!:\n'
              )
            else
              local success, result = pcall(function()
                oat._patchFunction(func, actor)(unpack(v[2]))
              end)
              if not success then
                error(
                  'uranium: error on \'' .. name .. '\' initialization on ' .. v[3].short_src .. ':' .. v[3].currentline .. ':\n' ..
                  result
                )
              end
            end
          end
          -- now that we know there's no poisonous methods in queue, let's offload them
          for _, v in ipairs(queue) do
            table.insert(M._globalQueue, {actor, v})
          end
          -- let's also properly route everything from the proxied actor to the actual actor
          lockedActor = actor
          -- and now let's run the initcommands
          for _, c in ipairs(initCommands) do
            local func = c[1]
            local success, result = pcall(function()
              func(actor)
            end)
            if not success then
              error(
                'uranium: error on \'' .. name .. '\' InitCommand defined on ' .. v[3].short_src .. ':' .. v[3].currentline .. ':\n' ..
                result
              )
            end
          end
          -- to make mr. Garbage Collector's job easier
          initCommands = {}
          queueRepresentation = nil
          queue = {}
        end
      else
        return function(...)
          if M._actorsInitialized then return end
          if key == 'addcommand' and arg[2] == 'Init' then
            table.insert(initCommands, {arg[3], debug.getinfo(2, 'Sl')})
          else
            table.insert(queue, {key, arg, debug.getinfo(2, 'Sl')})
          end
        end
      end
    end,
    __newindex = function()
      error('uranium: cannot set properties on actors!', 2)
    end,
    __tostring = function() return 'Proxy of ' .. name end,
    __name = name
  })
end

local function createGenericFunc(type)
  return function()
    if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
    if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
    local actor = createProxyActor(type)
    table.insert(M._actorQueue, {
      type = type,
      init = function(a)
        actor.__lock(a)
      end
    })
    actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
    return actor
  end
end

---@return Quad
--- Defines a Quad actor.
Quad = createGenericFunc('Quad')
---@return ActorProxy
--- Defines an ActorProxy actor.
ActorProxy = createGenericFunc('ActorProxy')
---@return Polygon
--- Defines a Polygon actor.
Polygon = createGenericFunc('Polygon')
---@return ActorFrameTexture
--- Defines an ActorFrameTexture actor.
ActorFrameTexture = createGenericFunc('ActorFrameTexture')

---@param file string | nil
---@return Sprite
--- Defines a Sprite actor.
function Sprite(file)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  --if not file then error('uranium: cannot create a Sprite without a file', 2) end
  local actor = createProxyActor('Sprite')
  local type = nil
  if not file then type = 'Sprite' end
  table.insert(M._actorQueue, {
    type = type,
    file = file and uranium.dir .. file,
    init = function(a)
      actor.__lock(a)
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@return ActorFrame
---@see addChild
--- Defines an ActorFrame. Add children to it with `addChild`.
function ActorFrame()
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  local actor = createProxyActor('ActorFrame')
  table.insert(M._actorQueue, {
    type = 'ActorFrame',
    init = function(a)
      actor.__lock(a)
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  oat._actorAssociationTable[actor] = {}
  return actor
end

local function isShaderCode(str)
  return string.find(str or '', '\n')
end

---@param frag string | nil
---@param vert string | nil
---@return RageShaderProgram
--- Defines a shader. `frag` and `vert` can either be filenames or shader code.
function Shader(frag, vert)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  local actor = createProxyActor('RageShaderProgram')

  local fragFile = frag
  local vertFile = vert

  local isFragShaderCode = isShaderCode(frag)
  local isVertShaderCode = isShaderCode(vert)

  if isFragShaderCode then fragFile = nil end
  if isVertShaderCode then vertFile = nil end

  if (frag and vert) and ((isFragShaderCode and not isVertShaderCode) or (not isFragShaderCode and isVertShaderCode)) then
    error('uranium: cannot create a shader with 1 shader file and 1 shader code block', 2)
  end

  table.insert(M._actorQueue, {
    type = 'Sprite',
    frag = fragFile and ('../' .. fragFile) or 'nop.frag',
    vert = vertFile and ('../' .. vertFile) or 'nop.vert',
    init = function(a)
      a:hidden(1)
      actor.__lock(a:GetShader())

      -- shader code stuff
      if isFragShaderCode or isVertShaderCode then
        a:GetShader():compile(vert or '', frag or '')
      end
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@param file string
---@return RageTexture
--- Defines a texture.
function Texture(file)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  if not file then error('uranium: cannot create a texture without a file', 2) end
  local actor = createProxyActor('RageTexture')

  table.insert(M._actorQueue, {
    file = file and uranium.dir .. file,
    init = function(a)
      a:hidden(1)
      actor.__lock(a:GetTexture())
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@param file string
---@return Model
--- Defines a Model actor.
function Model(file)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  if not file then error('uranium: cannot create a Model without a file', 2) end
  local actor = createProxyActor('Model')
  table.insert(M._actorQueue, {
    type = nil,
    file = file and uranium.dir .. file,
    init = function(a)
      actor.__lock(a)
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@param font string?
---@param text string?
---@return BitmapText
--- Defines a BitmapText actor.
function BitmapText(font, text)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  local actor = createProxyActor('BitmapText')
  table.insert(M._actorQueue, {
    type = 'BitmapText',
    font = font or 'common',
    init = function(a)
      if text then a:settext(text) end
      actor.__lock(a)
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@param file string
---@return ActorSound
--- Defines an ActorSound actor.
function ActorSound(file)
  if M._actorsInitializing then error('uranium: cannot create an actor during actor initialization!!', 2) end
  if M._actorsInitialized then error('uranium: cannot create an actor during runtime!!', 2) end
  if not file then error('uranium: cannot create an ActorSound without a file', 2) end
  local actor = createProxyActor('ActorSound')
  table.insert(M._actorQueue, {
    type = 'ActorSound',
    file = uranium.dir .. file,
    init = function(a)
      actor.__lock(a)
    end
  })
  actor.__queueRepresentation(M._actorQueue[#M._actorQueue])
  return actor
end

---@param frame ActorFrame
---@param actor Actor
--- Adds a child to an ActorFrame. **Please be aware of the side-effects!**
function addChild(frame, actor)
  if not frame or not actor then
    error('uranium: frame and actor must both Exist', 2)
  end
  if M._actorsInitializing then
    error('uranium: cannot create frame-child associations during actor initialization', 2)
  end
  if M._actorsInitialized then
    error('uranium: cannot create frame-child associations after actors have been initialized', 2)
  end
  if not frame.__lock then
    error('uranium: ActorFrame passed into addChild must be one instantiated with ActorFrame()!', 2)
  end
  if not actor.__lock then
    error('uranium: trying to add a child to an ActorFrame that isn\'t an actor; please read the first half of \'ActorFrame\'', 2)
  end
  M._actorAssociationQueue[actor.__queue] = frame.__queue
  table.insert(oat._actorAssociationTable[frame], actor)
end

function M._transformQueueToTree()
  local tree = {}
  local paths = {}
  local iter = 0
  while #M._actorQueue > 0 do
    iter = iter + 1
    if iter > 99999 then
      error('uranium: failed to transform queue to tree: reached maximum iteration limit! is there an actor with an invalid actorframe?')
    end
    for i = #M._actorQueue, 1, -1 do
      v = M._actorQueue[i]
      local insertInto
      if not M._actorAssociationQueue[v] then
        insertInto = tree
      else
        if paths[M._actorAssociationQueue[v]] then
          insertInto = paths[M._actorAssociationQueue[v]]
        end
      end
      if insertInto then
        if v.type == 'ActorFrame' then
          table.insert(insertInto, {init = v.init})
          table.remove(M._actorQueue, i)
          paths[v] = insertInto[#insertInto]
        else
          table.insert(insertInto, v)
          table.remove(M._actorQueue, i)
        end
      end
    end
  end
  M._actorTree = tree
end

return M