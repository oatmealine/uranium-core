xero = oat
xero.foreground = oat._main
xero.MIRIN_VERSION = 'URANIUM-5.0.1'


-- Load all of the core .lua files
-- The order DOES matter here:
-- std.lua needs to be loaded first
-- template.lua needs to be last
require('stdlib.mirin.std')
require('stdlib.mirin.sort')
require('stdlib.mirin.ease')
require('stdlib.mirin.template')

local xeroActorsAF = Quad()

function uranium.init()
  xero.init_command(xeroActorsAF)
end