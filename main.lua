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
-- local btnChangeLvl = nil
-- local btnPressed = false

-- local function btnReleased(event)
-- 	player:setSequence("up")
-- 	player:play()

-- 	btnPressed = false
-- end

-- local function nextLvl(event)
-- 	if (isActive) then
-- 		player
-- 	end
-- end

-- this creates all the display objects for the level
-- myLevel will contain all the display groups so you can access all the elements of the level
myLevel = LD:loadLevel("level1")

local function nextLvl(event)
	if (isActive) then
		-- player.setSequence("next")
		-- player:play()

		-- btnPressed = true
		myLevel = LD:loadLevel("Level2")
	end
end

btnChangeLvl.onPress = nextLvl