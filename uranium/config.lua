-- Internal module for Uranium's configuration system, meant to be used
-- for other systems to access the values.
local M = {}

-- Uranium's configuration system, providing methods to configure parts
-- of the template.
uranium.config = {}

M.resetOnFrameStart = false

-- Toggle actor resetting on frame start behavior by default.
---@param bool boolean
function uranium.config.resetOnFrameStart(bool)
  M.resetOnFrameStart = bool
end

---@type table<Actor, boolean>
M.resetActorOnFrameStart = {}

-- Toggle actor resetting on frame start for individual actors. `bool` defaults to the opposite of your `resetOnFrameStart` config
---@param actor Actor
---@param bool boolean | nil
function uranium.config.resetActorOnFrameStart(actor, bool)
  if bool == nil then bool = not M.resetOnFrameStart end
  M.resetActorOnFrameStart[actor.__raw or actor] = bool
end

M.hideThemeActors = true

-- Toggle if theme actors (lifebars, scores, song names, etc.) are hidden. Must be toggled **before** `init`.
---@param bool boolean
function uranium.config.hideThemeActors(bool)
  M.hideThemeActors = bool
end

return M