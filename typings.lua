---@meta

-- cleaning up some notitg typing jank... ehe
---@alias int number
---@alias float number
---@alias Quad Actor
---@alias void nil
---@type GameState
GAMESTATE = {}
---@type PrefsManager
PREFSMAN = {}
---@type ScreenManager
SCREENMAN = {}
---@type ProfileManager
PROFILEMAN = {}
---@type RageInput
INPUTMAN = {}

---@type number
--- A simple timer. Ticks upwards at a rate of 1/sec.
---
--- **The start time is undefined!** This uses `os.clock()`, meaning this will be inconsistent between modfile starts.
---
--- It's recommended to only use this for eg. `math.sin`, rotations, and other similar visual effects. If you want a proper timer, see `b`.
t = 0

---@type number
--- The amount of beats that have passed since the start of the file.
b = 0

---@type ActorFrame
--- The root ActorFrame. Use this for `addcommand` and similar!
_main = {}

---@type number
--- The center of the screen on the X axis. Equal to `SCREEN_CENTER_X`.
scx = 0
---@type number
--- The center of the screen on the Y axis. Equal to `SCREEN_CENTER_Y`.
scy = 0
---@type number
--- The screen width. Equal to `SCREEN_WIDTH`.
sw = 0
---@type number
--- The screen height. Equal to `SCREEN_HEIGHT`.
sh = 0
---@type number
--- The display width.
dw = 0
---@type number
--- The display height.
dh = 0

--- Equivalent to a modfile-sandboxed `_G`, similar to Mirin's `xero`. You shouldn't need this; and if you do, *what are you doing?*
oat = _G