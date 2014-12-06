-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

local physics = require ("physics")
physics.start()

local LD = require ("lib.LD_LoaderG2")
 
local myLevel = {}

-- this creates all the display objects for the level
-- myLevel will contain all the display groups so you can access all the elements of the level
myLevel = LD:loadLevel("level1")
