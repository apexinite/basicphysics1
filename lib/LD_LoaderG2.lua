------------------------------------
-- Level Director - LD_LoaderG2 v2.5
------------------------------------
-- Copyright: 2014 Retrofit Productions

-- Permission is hereby granted, free of charge, to any person obtaining a copy of 
-- this software and associated documentation files (the "Software"), to deal in the 
-- Software without restriction, including without limitation the rights to use, copy, 
-- modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
-- and to permit persons to whom the Software is furnished to do so, subject to the 
-- following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all copies 
-- or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.

--module(..., package.seeall)
require "config"

require("lib.LD_HelperG2")

LD_Loader = {}

-------------------------------------------------
function LD_Loader:loadLevel(levelName)
-------------------------------------------------
	local levelsFolder = ''
	
	-- check if there is a folder in the config file for levels
	if (application.LevelDirectorSettings.levelsSubFolder ~= nil) then
		levelsFolder = application.LevelDirectorSettings.levelsSubFolder
		levelsFolder = levelsFolder .. "."
	end

	-- check if there is a folder in the config file for images
	if (application.LevelDirectorSettings.imagesSubFolder ~= nil) then
		LD_Helper:instance().imgSubFolder = application.LevelDirectorSettings.imagesSubFolder
		LD_Helper:instance().imgSubFolder = LD_Helper:instance().imgSubFolder .. "/"
	end
	
	-- load and create level instance
	local level = require(levelsFolder .. levelName):createLevel()
	
	--unload required level module as now stored in 'level'
	package.loaded[levelsFolder .. levelName] = nil
    _G[levelsFolder .. levelName] = nil	
	
	-- retrun instance
	setmetatable(level, { __index = LD_Loader })
	
	return level
	
end -- loadLevel

----------------------------------------------------
function LD_Loader:addObject(layerName, obj)
----------------------------------------------------
	return LD_Helper:instance():addObject(self.layers[layerName], obj)
end -- addObject

----------------------------------------------------
function LD_Loader:createObject(layerName, objProps)
----------------------------------------------------
	return LD_Helper:instance():createObject(self.layers[layerName], objProps,self.assets)
end -- createObject

--------------------------------------------------------
function LD_Loader:getLayer(layerName)
--------------------------------------------------------
	local layer = self.layers[layerName]
	
	return layer

end -- getLayer

---------------------------------------------
function LD_Loader:getObject(objectName)
---------------------------------------------
	-- searches all layers
	
	local obj = nil
	for i = 1, (#self.layers) do
		for k, v in pairs (self.layers[i].objects) do
			if objectName == v.name then
				obj = v
				break
			end
		end
	end
	return obj
end -- getObject

--------------------------------------------------------
function LD_Loader:getLayerObject(layerName,objectName)
--------------------------------------------------------
	local obj = nil
	for k, v in pairs (self.layers[layerName].objects) do
		if objectName == v.name then
			obj = v
			break
		end
	end
	
	return obj

end -- getLayerObject

--------------------------------------------------------
function LD_Loader:setLayerVisible(layerName,isVisible)
--------------------------------------------------------
	for k, v in pairs (self.layers[layerName].objects) do
		v.view.isVisible = isVisible
	end
	
end -- setLayerVisible

------------------------------------
function LD_Loader:initLevel()
------------------------------------
	-- check for any objects set to follow a path with autostart
	local obj
	for i = 1, (#self.layers) do
		--print ("init:" , self.layers[i].name)
		for idx, obj in pairs (self.layers[i].objects) do
			if (obj.followPathProps) then
				if (obj.followPathProps.path ~= '' and obj.followPathProps.autoStart) then
					local path = self:getObject(obj.followPathProps.path)
					if (path) then
						--print (obj.name,obj.followPathProps.path)
						obj:followPath(path, obj.followPathProps)
					end
				end
			end
		end
	end
end

----------------------------------------------
function LD_Loader:objectsWithClass(className)
----------------------------------------------
	local objects = {}
	for i = 1, (#self.layers) do
		for k, v in pairs (self.layers[i].objects) do
			if className == v.class then
				objects[#objects+1] = v
			end
		end
	end
	return objects
end -- objectsWithClass

-------------------------------------------------------------------
function LD_Loader:layerObjectsWithClass(layerName, className)
-------------------------------------------------------------------
	local layerObjects = {}
	for k, v in pairs (self.layers[layerName].objects) do
		if className == v.class then
			layerObjects[#layerObjects+1] = v
  		end
	end
	return layerObjects
end -- objectsWithClass

-------------------------------------------------------------------
function LD_Loader:layerObjects(layerName)
-------------------------------------------------------------------
	local layerObjects = {}
	for k, v in pairs (self.layers[layerName].objects) do
		layerObjects[#layerObjects+1] = v
	end
	return layerObjects
end -- objectsWithClass

-------------------------------------------------------------------
function LD_Loader:getAllObjects()
-------------------------------------------------------------------
	local layerObjects = {}
	
	for i = 1, (#self.layers) do
		for k, v in pairs (self.layers[i].objects) do
			layerObjects[#layerObjects+1] = v
		end
	end
	
	return layerObjects
end -- objectsWithClass

-------------------------------------------------------------------
function LD_Loader:removeLayerObject(layerName,objectName)
-------------------------------------------------------------------
	for k, v in pairs (self.layers[layerName].objects) do
		if objectName == v.name then
			table.remove(self.layers[layerName].objects,k)
			v:delete()
			v = nil
			break
		end
	end
end -- removeLayerObject

-------------------------------------------------------------------
function LD_Loader:removeLayerObjectsWithClass(layerName,className)
-------------------------------------------------------------------
	for k, v in pairs (self.layers[layerName].objects) do
		if className == v.class then
			table.remove(self.layers[layerName].objects,k)
			v:delete()
			v = nil
			--self.layers[layerName].objects[k] = nil
		end
	end
end -- removeLayerObjectsWithClass

----------------------------------------------------
function LD_Loader:removeObjectsWithClass(className)
----------------------------------------------------
	for i = 1, (#self.layers) do
		for k, v in pairs (self.layers[i].objects) do
			if className == v.class then
				table.remove(self.layers[i].objects,k)
				v:delete()
				v = nil
				--self.layers[i].objects[k] = nil
			end
		end
	end
end -- removeObjectsWithClass

--------------------------------------------------------------------
function LD_Loader:addEventListenerToAllObjects(eventName, listener)
--------------------------------------------------------------------
	--must be done before load level
	LD_Helper:instance().eventHandlers[eventName] = listener
end -- addEventListenerToAllObjects

--------------------------------------------------------------------
function LD_Loader:cullingEngine()
--------------------------------------------------------------------
	-- searches all layers
	
	local obj = nil
	for i = 1, (#self.layers) do
		for k, v in pairs (self.layers[i].objects) do
			if objectName == v.name then
				obj = v
				break
			end
		end
	end
	return obj

end

---------------------------------------------------------
function LD_Loader:removeLevel(retainSpriteSheetTextures)
---------------------------------------------------------
	-- remove the main display group
	for i = 1, (#self.layers) do
		-- removed objects in layer
		for k2 = #self.layers[i].objects, 1, -1 do
			o = self.layers[i].objects[k2]
			--print (self.layers[i].name,o.name)
			table.remove(self.layers[i].objects,k2)
			o:delete()
			o = nil
		end
		
		-- remove layer
		self.layers[i].objects = nil
		self.layers[i].view:removeSelf()
		self.layers[i] = nil
	end
	self.layers = nil
	--self:removeSelf()
	display.remove(self.view)
	
	self.assets.spriteSheetData = nil
	self.assets = nil
	
	LD_Helper:instance():cleanUp(retainSpriteSheetTextures)
	self = nil
end -- removeLevel

----------------------------
function LD_Loader:cleanUp()
----------------------------
	if (self) then
		self:removeLevel()
	end
	
	LD_Helper = nil
end -- cleanUp

return LD_Loader
