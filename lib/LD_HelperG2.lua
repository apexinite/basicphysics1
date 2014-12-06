----------------------------------
-- Level Director - LD_Helper v3.2
----------------------------------
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
require ("config")

bezier = require('lib.bezier')

LD_Helper = {}
LD_Helper_instance = nil
local tInsert = table.insert
local round = math.round

-------------------------
function LD_Helper:init()
-------------------------

	if tonumber(system.getInfo("build")) < 2013.2076 then
		print("Warning: This build of Corona SDK is not supported.")
	end
	
	local vars = {
		imgSubFolder = "",
		spriteSheets={},
		eventHandlers={},
		transitions={},
		listeners={},
		contentWidth = display.contentWidth - ( display.screenOriginX * 2 ),
		contentHeight = display.contentHeight - ( display.screenOriginY * 2 ),
		contentScaleX = display.contentScaleX,
		contentScaleY = display.contentScaleY,
		runtime = 0,
		nParallaxObjectWrap = "LD_ParallaxObjectWrap",
		nPathEnded = "LD_PathEnded",
		nPathObjectEnded = "LD_PathObjectEnded",		
		_DEBUG = false -- enable _DEBUG print
	}
	setmetatable(vars, { __index = LD_Helper })	
	
	LD_Helper_instance = vars
	
	return vars
		
end

-----------------------------
function LD_Helper:instance()
-----------------------------

	if(LD_Helper_instance == nil) then
		return self:init()
	end
	
	return LD_Helper_instance
end

-- Utility Functions
------------------------------------------------
function toInt(value)
------------------------------------------------
	if(value > 0)then
		return math.floor(value)
	else
		return math.ceil(value)
	end
	return 0;
end

------------------------------------------------
function findAngle ( srcPos, dstPos )
------------------------------------------------ 
	local xDist = dstPos.x-srcPos.x
   	local yDist = dstPos.y-srcPos.y
    local angle = math.deg( math.atan( yDist/xDist ) )
        
    if ( srcPos.x < dstPos.x ) then 
        angle = angle+90
    else 
        angle = angle-90 
    end
        
    return angle
end

------------------------------------------------
function MIN(A, B)
------------------------------------------------
	if(A < B)then
		return A
	else
		return B
	end
	
	return A
end

------------------------------------------------
function MAX(A, B)
------------------------------------------------
	if(A > B)then
		return A
	else
		return B
	end
	
	return A
end

---------------------------------
function LD_Helper:getDeltaTime()
---------------------------------
   local temp = system.getTimer()  --Get current game time in ms
   local dt = (temp-self.runtime) / (1000/display.fps)  --60fps or 30fps as base
   self.runtime = temp  --Store game time
   return dt
end

-- Main functions
----------------------------------------------------------------
function LD_Helper:applyPhysics(obj, objPhysics, xScale, yScale)
----------------------------------------------------------------
	local _physics = objPhysics

	if (_physics) then
		if (_physics.isEnabled == true) then
		
			local complexBodies = {}
			
			local shapes = _physics.shapes
			for i = 1, #shapes do
				local shape = shapes[i]
				local polygon = shape.shape
				local colFilter = ''
				local r = shape.radius

				if shape.categoryBits > 0  then
					colFilter = { categoryBits = shape.categoryBits , maskBits = shape.maskBits, groupIndex = shape.groupIndex}
				end
				
				if shape.bodyShape == "Round" then
					if _physics.source == 'Asset' and (xScale ~= 1.0 or yScale ~= 1.0) then
						r = xScale * r
					end
					complexBodies[i] = {density =  shape.density, friction = shape.friction, bounce = shape.bounce, radius = r, filter = colFilter}	
				elseif shape.bodyShape == "Rectangle" then
					complexBodies[i] = {density =  shape.density, friction = shape.friction, bounce = shape.bounce, filter = colFilter}
				else
					-- scale points
					local scalePoints = {}
					
					--if created from asset then we may need to scale it, otherwise if coming from pre created object it should already be scaled.
					if _physics.source == 'Asset' and (xScale ~= 1.0 or yScale ~= 1.0) then
						local alt = 1 -- x or y
						for ci,coordinate in ipairs(polygon) do
							if alt == 1 then
								scalePoints[ci] = xScale* coordinate
							else
								scalePoints[ci] = yScale* coordinate
							end
							alt = alt * -1 
						end
					else
						scalePoints = polygon -- no scale
					end
					complexBodies[i] = {density =  shape.density, friction = shape.friction, bounce = shape.bounce, shape = scalePoints, filter = colFilter}	
				end
			end
			
			if (#complexBodies) > 0 then
				physics.addBody(obj,_physics.bodyType, unpack(complexBodies))
				-- apply physic attributes
				if (_physics.isFixedRotation) then obj.isFixedRotation = _physics.isFixedRotation end
				if (_physics.isSleepingAllowed) then obj.isSleepingAllowed = _physics.isSleepingAllowed end
				if (_physics.angularDamping) then obj.angularDamping = _physics.angularDamping end
				if (_physics.linearDamping) then obj.linearDamping = _physics.linearDamping end
				if (_physics.isSensor) then obj.isSensor = _physics.isSensor end
				if (_physics.isBullet) then obj.isBullet = _physics.isBullet end
				if (_physics.gravityScale) then obj.gravityScale = _physics.gravityScale end
			end
			
		end
	end

end

----------------------------------------------------------------------------------------------------
-- assetName 	: name of asset to create object from
-- assets		: table containing assets for a level
-----------------------------------------------------------------------------------------------------
function LD_Helper:getSpriteSheet(assetName, assets)
-----------------------------------------------------------------------------------------------------
	local spriteSheet = nil

    if (assets[assetName]) then
        local asset = assets[assetName]
	
		--if part of spritesheet check if it already exists
		if (self.spriteSheets[asset.spriteSheetName] == nil) then
			--create new spritesheet and sprite set
			local options = assets.spriteSheetData[asset.spriteSheetName]  
			options.sheetContentWidth = assets.spriteSheetData[asset.spriteSheetName].frames.sheetContentWidth
			options.sheetContentHeight = assets.spriteSheetData[asset.spriteSheetName].frames.sheetContentHeight
            self.spriteSheets[asset.spriteSheetName] = graphics.newImageSheet( self.imgSubFolder .. asset.file, options )    		
		end
		
		spriteSheet = self.spriteSheets[asset.spriteSheetName]
	end
	
	return spriteSheet
	
end -- getSpriteSheet

----------------------------------------------------------------------------------------------------
-- assets		: table containing assets for a level
-- fillProps 	: fill properties
-----------------------------------------------------------------------------------------------------
function LD_Helper:getFillParam(assets, fillProps, styleProps)
-----------------------------------------------------------------------------------------------------
	
	local f = nil
	local asset = nil 
	local st = styleProps
	local fp = fillProps
	
	if (fp.fillType == 1) then
		-- imagesheet
		f = { type = "image", sheet = self:getSpriteSheet(fp.fillAssetName, assets), frame = fp.fillFrame}
	elseif (fp.fillType == 2) then
		-- file
		if (assets[fp.fillAssetName]) then
			asset = assets[fp.fillAssetName]
			f = { type = "image", filename = self.imgSubFolder .. asset.file}
		end
	else
		-- colour
		f = nil --to support non pro users
	end
	
	return f
	
end -- getfillParam

----------------------------------------------------------------------------------------------------
-- obj 				: object to fill
-- fillProps 		: fill properties
-- gradientProps 	: gradient properties
-----------------------------------------------------------------------------------------------------
function LD_Helper:setFillColor(obj, styleProps, gradientProps)
-----------------------------------------------------------------------------------------------------
	local gp = gradientProps
	local st = styleProps
	local fill = nil
	
	if (gp) then
		if (gp.direction > 0) then
			fill = {type = 'gradient'}
			fill.color1 = {st.fillColorR,st.fillColorG, st.fillColorB, st.fillColorA}
			fill.color2 = {gp.fillColorR,gp.fillColorG, gp.fillColorB, gp.fillColorA}
			
			if (gp.direction == 1) then 
				fill.direction = 'up'
			elseif (gp.direction == 2) then
				fill.direction = 'down'
			elseif (gp.direction == 3) then
				fill.direction = 'left'
			elseif (gp.direction == 4) then
				fill.direction = 'right'
			end
		end -- direction
	end
	
	if (fill) then
		obj:setFillColor(fill)
	else
		obj:setFillColor (st.fillColorR,st.fillColorG, st.fillColorB, st.fillColorA)
	end
end -- setFillColor

----------------------------------------------------------------------------------------------------
-- assetName 	: name of asset to create object from
-- assets		: table containing assets for a level
-- x 			: x position
-- y 			: y position
-- xScale 		: x scale factor - set to 1.0 for no scale
-- yScale 		: y scale factor - set to 1.0 for no scale
-- objPhysics	: optional - use physics from an exisitng object (overrides asset physics)
---------------------------------------------------------------------------------------------------------
function LD_Helper:createObjectFromAsset(assetName, assets, x, y, xScale, yScale, objPhysics, noPhysics)
---------------------------------------------------------------------------------------------------------
    local obj = nil
	local applyPhysics = true 
	
	if (noPhysics) then
		applyPhysics = noPhysics
	end
	
    if (assets[assetName]) then
        local asset = assets[assetName]
        if (asset.frame == 0) then
            obj = display.newImageRect( self.imgSubFolder .. asset.file, asset.width * xScale , asset.height * yScale )
        else
			local spriteSheet = nil
			
			spriteSheet = self:getSpriteSheet(assetName, assets)
			
			if self._DEBUG then print (assetName .. " sequence count " .. #asset.sequenceData, asset.sequenceData) end
			if (#asset.sequenceData == 0) then
				obj = display.newImage( spriteSheet , asset.frame)
			else
				obj = display.newSprite( spriteSheet , asset.sequenceData)
				
				if (asset.sequenceInfo) then
					if (asset.sequenceInfo.default ~= '') then
						obj:setSequence(asset.sequenceInfo.default)
						if (asset.sequenceInfo.play == true) then
							obj:play()
						end
					end				
				end			
			end

            obj.currentFrame = asset.frame
			
			obj.xScale = xScale
			obj.yScale = yScale
        end
		
        if (obj) then
			obj.x = x
			obj.y = y
			
			if (applyPhysics) then
				local _physics = asset.physics
				
				if (objPhysics) then
					_physics = objPhysics
				end
				
				self:applyPhysics(obj, _physics, xScale, yScale)
			end
		end
    end
	
    return obj
	
end -- createObjectFromAsset

---------------------------------------------------------
-- parentGroup 	: parent/layer group to insert object into
-- obj	 		: obj view
--------------------------------------------------------------
function LD_Helper:addObject(parentGroup, objView)
--------------------------------------------------------------
	local obj = {}
	-- apply general properties
	if (objView) then
		obj.view = objView
		
		obj.name = objView.name or ''
		obj.class = objView.class or ''
		obj.layerName = parentGroup.name
		obj.markX, obj.markY = 0,0
		obj.ldType = "External"
			
		-- add object to layer view
		parentGroup.view:insert(obj.view)
			
		obj.markX = obj.view.x    -- store x location of object        
		obj.markY = obj.view.y    -- store y location of object	    
		
		-- add object to layer table
		tInsert(parentGroup.objects,obj)	

		function obj:delete()
			Runtime:removeEventListener( "enterFrame", obj )
			
			if (obj.view) then
				display.remove( obj.view )
				obj.view:removeSelf()
			end
		end
		
	end
	
end --addObject

---------------------------------------------------------
-- parentGroup 	: parent/layer group to insert object into
-- objProps	: table containing object properties
-- assets	: optional assets to create objects from
--------------------------------------------------------------
function LD_Helper:createObject(parentGroup, objProps, assets)
--------------------------------------------------------------
	local obj = nil
	local st = nil 
	local i = 0 
	local x,y,x1,y1
	local fill = {}
	local fp = nil
	local f = nil
	local gf = nil 
		
	if (objProps.assetName ~= nil and objProps.objType == nil) then
		objProps.objType = 'LDObjectImage'
	end
	
	if (objProps.xScale == nil) then
		objProps.xScale = 1
	end
	if (objProps.yScale == nil) then
		objProps.yScale = 1
	end
	
	if (objProps.styleProps) then
		st = objProps.styleProps
	end
	
	if (objProps.fillProps) then
		fp = objProps.fillProps
	end
	
	if (objProps.gradientProps) then
		gf = objProps.gradientProps
	end
	
	---------------------------------------------
	if (objProps.objType == 'LDObjectImage') then
	---------------------------------------------
		obj = {}
		obj.view = nil 
	
		if (objProps.assetName) then
			if (objProps.anchorX == nil) then
				objProps.anchorX = assets[objProps.assetName].anchorX or 0.5
			end
			if (objProps.anchorY == nil) then
				objProps.anchorY = assets[objProps.assetName].anchorY or 0.5
			end

			obj.view = self:createObjectFromAsset(objProps.assetName, assets, objProps.x, objProps.y, objProps.xScale, objProps.yScale, objProps.physics)
			obj.assetName = objProps.assetName
			objProps.class = objProps.class or assets[objProps.assetName].class
		else
			obj.view = display.newImageRect(self.imgSubFolder .. objProps.file,objProps.width,objProps.height) 
			obj.x = objProps.x
			obj.y = objProps.y
			self:applyPhysics(obj, objProps.physics, objProps.xScale, objProps.yScale)
		end


	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectRectangle') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 
		local r = 0 
				
		r = (st.cornerRadius or 0)
		
		if (r > 0) then
			obj.view = display.newRoundedRect(objProps.x,objProps.y, objProps.width, objProps.height,r) 
		else
			obj.view = display.newRect(objProps.x,objProps.y, objProps.width, objProps.height) 
		end
		
		if (obj.view) then
			if (st) then
				obj.view.strokeWidth = st.strokeWidth
				obj.view:setStrokeColor (st.strokeColorR,st.strokeColorG,st.strokeColorB, st.strokeColorA)
				--obj.view:setFillColor (st.fillColorR,st.fillColorG, st.fillColorB, st.fillColorA)
				self:setFillColor(obj.view, st, gf)
				
				if (fp) then
					f = self:getFillParam(assets, fp, st)
					if (f) then
						obj.view.fill = f
					end
				end
			end
			
			self:applyPhysics(obj.view, objProps.physics, objProps.xScale, objProps.yScale)
			
		end
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectEllipse') then
	-----------------------------------------------------
		obj = {}
		obj.view = display.newCircle(objProps.x,objProps.y, objProps.physics.shapes[1].radius) 
		if (obj.view and objProps.styleProps) then
			obj.view.strokeWidth = st.strokeWidth
			obj.view:setStrokeColor (st.strokeColorR,st.strokeColorG,st.strokeColorB, st.strokeColorA)
			--obj.view:setFillColor (st.fillColorR,st.fillColorG, st.fillColorB, st.fillColorA)
			self:setFillColor(obj.view, st, gf)
			
			if (fp) then
				f = self:getFillParam(assets, fp, st)
				if (f) then
					obj.view.fill = f
				end
			end
			
			self:applyPhysics(obj.view, objProps.physics, objProps.xScale, objProps.yScale)
		end
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectBezier') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 
		
		if (objProps.pointProps and objProps.styleProps) then
			local x,y, x1, y1
			
			obj.view = display.newGroup()

			obj.xPoints = objProps.pointProps.xPoints
			obj.yPoints = objProps.pointProps.yPoints
			obj.view.x = objProps.x
			obj.view.y = objProps.y
			obj.view.contentWidth = objProps.width * self.contentScaleX
			obj.view.contentHeight = objProps.height * self.contentScaleY
			
			--switch all points to be relative to x,y coords of main group
			for i =1,#obj.xPoints do
				x,y = obj.xPoints[i],obj.yPoints[i]
				obj.xPoints[i] = x - obj.view.x
				obj.yPoints[i] = y - obj.view.y		
				if self._DEBUG then print (i, obj.xPoints[i], obj.yPoints[i]) end
			end
			
			obj.isBezier = true
			obj.curve = bezier:curve(obj.xPoints, obj.yPoints)
			
			i = 0 
			
			if (objProps.pointProps.outputType == 'Display') then
				local idx = 1
				for i=0.01, 1, 0.01 do
					x, y = obj.curve(i)
					x1,y1 = obj.curve(i+0.01)
					if self._DEBUG then print(objProps.name, i, x,y,x1,y1) end
					obj.line = display.newLine(x,y,x1,y1) --use appendline if no physics?
					obj.line.anchorX = objProps.anchorX
					obj.line.anchorY = objProps.anchorY
					
					obj.line:setStrokeColor(st.strokeColorR,st.strokeColorG,st.strokeColorB)
					obj.line.strokeWidth = st.strokeWidth
					
					if (objProps.physics.isEnabled) then
						objProps.physics.shapes[idx] = {
								density = objProps.physics.shapes[1].density,
								friction = objProps.physics.shapes[1].friction,
								bounce = objProps.physics.shapes[1].bounce,
								--shape = {x, y, x1, y1,x,y,x1,y1},  -- corona deprecated line physics
								shape = {x,y,  x+1, y,   x1+1,y1,  x1-1,y1, x,y},
								categoryBits = objProps.physics.shapes[1].categoryBits,
								maskBits  = objProps.physics.shapes[1].categoryBits,
								groupIndex = objProps.physics.shapes[1].groupIndex
								}
						idx = idx + 1
					end
					obj.view:insert(obj.line)
				end
				
				if (objProps.physics.isEnabled) then
					self:applyPhysics(obj.view, objProps.physics, 1, 1)
				end
			end
		end
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectPath') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 

		if (objProps.pointProps and objProps.styleProps) then
			local x,y,x1,y1 = 0,0,0,0
			
			obj.view = display.newGroup() -- create a display group so that scrolling works correctly and allows whole path to be wrapped.
				
			obj.xPoints = objProps.pointProps.xPoints
			obj.yPoints = objProps.pointProps.yPoints
			obj.isBezier = false
			obj.view.x = objProps.x
			obj.view.y = objProps.y
			obj.width = objProps.width
			obj.height = objProps.height
			
			--switch all points to be relative to x,y coords of main group
			for i =1,#obj.xPoints do
				x,y = obj.xPoints[i],obj.yPoints[i]
				
				obj.xPoints[i] = x - obj.view.x
				obj.yPoints[i] = y - obj.view.y		
			end
						
			if (objProps.pointProps.outputType == 'Display') then
				for i =1,#obj.xPoints-1 do
					x,y = obj.xPoints[i], obj.yPoints[i] 
					x1,y1 = obj.xPoints[i+1],obj.yPoints[i+1] 
					
					if self._DEBUG then print(objProps.name, i, x,y,x1,y1) end
					obj.line = display.newLine(x, y, x1, y1)
					obj.line.anchorX = objProps.anchorX
					obj.line.anchorY = objProps.anchorY

					obj.line:setStrokeColor(st.strokeColorR,st.strokeColorG,st.strokeColorB)
					obj.line.strokeWidth = st.strokeWidth

					if (objProps.physics.isEnabled) then
						objProps.physics.shapes[i] = {
								density = objProps.physics.shapes[1].density,
								friction = objProps.physics.shapes[1].friction,
								bounce = objProps.physics.shapes[1].bounce,
								shape = {x,y,  x+1, y,   x1+1,y1,  x1-1,y1, x,y},
								categoryBits = objProps.physics.shapes[1].categoryBits,
								maskBits  = objProps.physics.shapes[1].categoryBits,
								groupIndex = objProps.physics.shapes[1].groupIndex
								}
					end
					-- add to image group
					obj.view:insert(obj.line)
				end
				if (objProps.physics.isEnabled) then
					self:applyPhysics(obj.view, objProps.physics, 1, 1)
				end

				obj.view.contentWidth = (obj.width * self.contentScaleX) 
				obj.view.contentHeight = (obj.height * self.contentScaleY)

			else
				-- no display so we work out how wide the path is so the parallax scroll routine knows when to wrap it.
				x = MAX(obj.xPoints[#obj.xPoints] - obj.xPoints[1],1) + 32 -- the 32 adds a little buffer as the objects following the path will be wider
				y = MAX(obj.yPoints[#obj.yPoints] - obj.yPoints[1],1) + 32 -- than the last point and the path will go offscreen and wrap before the object.
				obj.view.contentWidth = (x * self.contentScaleX) 
				obj.view.contentHeight = (y * self.contentScaleY)
			end

			--print (obj.x, obj.y , obj.contentWidth, obj.contentHeight)

		end
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectPolygon') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 
		if (objProps.pointProps and objProps.styleProps) then
			local x,y,x1,y1 = 0,0,0,0
			local vertices = {}
			
			obj.xPoints = objProps.pointProps.xPoints
			obj.yPoints = objProps.pointProps.yPoints
			obj.isBezier = false
			obj.x = objProps.x
			obj.y = objProps.y
			obj.width = objProps.width
			obj.height = objProps.height
			
			local v = 1
			--switch all points to be relative to x,y coords of main group
			for i =1,#obj.xPoints do
				x,y = obj.xPoints[i],obj.yPoints[i]
				obj.xPoints[i] = x - obj.x
				obj.yPoints[i] = y - obj.y		
				vertices[v]   = obj.xPoints[i]
				vertices[v+1] = obj.yPoints[i]
				v = v + 2
			end
						
			if (objProps.pointProps.outputType == 'Display') then
				--if self._DEBUG then print(objProps.name, i, x,y,x1,y1) end
				
				obj.view = display.newPolygon(obj.x, obj.y, vertices)
				obj.view:setStrokeColor(st.strokeColorR,st.strokeColorG,st.strokeColorB)
				obj.view.strokeWidth = st.strokeWidth
				self:setFillColor(obj.view, st, gf)

				if (fp) then
					f = self:getFillParam(assets, fp, st)
					if (f) then
						obj.view.fill = f
					end
				end

				if (objProps.physics.isEnabled) then
					objProps.physics.shapes[i] = {
							density = objProps.physics.shapes[1].density,
							friction = objProps.physics.shapes[1].friction,
							bounce = objProps.physics.shapes[1].bounce,
							shape = {x,y,x1,y1},
							categoryBits = objProps.physics.shapes[1].categoryBits,
							maskBits  = objProps.physics.shapes[1].categoryBits,
							groupIndex = objProps.physics.shapes[1].groupIndex
							}
				end
				
				if (objProps.physics.isEnabled) then
					self:applyPhysics(obj.view, objProps.physics, 1, 1)
				end

				obj.view.contentWidth = (obj.width * self.contentScaleX) 
				obj.view.contentHeight = (obj.height * self.contentScaleY)

			else
				-- no display so we work out how wide the path is so the parallax scroll routine knows when to wrap it.
				x = MAX(obj.xPoints[#obj.xPoints] - obj.xPoints[1],1) + 32 -- the 32 adds a little buffer as the objects following the path will be wider
				y = MAX(obj.yPoints[#obj.yPoints] - obj.yPoints[1],1) + 32 -- than the last point and the path will go offscreen and wrap before the object.
				obj.view.contentWidth = (x * self.contentScaleX) 
				obj.view.contentHeight = (y * self.contentScaleY)
			end

			--print (obj.x, obj.y , obj.contentWidth, obj.contentHeight)

		end	
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectText') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 

		if (objProps.textProps) then
			if (objProps.textProps.embossed) then
				obj.view = display.newEmbossedText(objProps.textProps.text,objProps.x,objProps.y,objProps.textProps.font,objProps.textProps.size)
			else
				obj.view = display.newText(objProps.textProps.text,objProps.x,objProps.y,objProps.textProps.font,objProps.textProps.size)
			end
			
			if (obj.view and objProps.styleProps) then
				obj.view.strokeWidth = st.strokeWidth
				obj.view:setFillColor (st.strokeColorR,st.strokeColorG,st.strokeColorB, st.strokeColorA)
				
				if (objProps.textProps.embossed) then
					local color = 
					{
						highlight = { r=objProps.textProps.embossHighlightColorR, g=objProps.textProps.embossHighlightColorG, b=objProps.textProps.embossHighlightColorB, a=objProps.textProps.embossHighlightColorA },
						shadow = { r=objProps.textProps.embossShadowColorR, g=objProps.textProps.embossShadowColorG, b=objProps.textProps.embossShadowColorB, a=objProps.textProps.embossShadowColorA }
					}
					obj.view:setEmbossColor(color)

				end
				self:applyPhysics(obj.view, objProps.physics, 1, 1)
			end
		end
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectCamera') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 
		obj.x = objProps.x
		obj.y = objProps.y
	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectButton') then
	-----------------------------------------------------
		local xScale, yScale = 1,1 
		local r = 0 
		
		obj = {}

		local w, h = objProps.width, objProps.height
		
		obj.view = display.newGroup()

		r = (st.cornerRadius or 0)

		------------------------------
		-- default rectangle
		------------------------------
		obj.rect = display.newGroup()
		
		if (fp) then
			if (fp.fillType == 4 and fp.fillAssetName ~= '') then
				xScale = (objProps.width / assets[fp.fillAssetName].width)
				yScale = (objProps.height / assets[fp.fillAssetName].height)
				obj.rect.img = self:createObjectFromAsset(fp.fillAssetName, assets, 0,0, xScale,yScale,nil,false)		
				if (obj.rect.img) then
					obj.rect:insert(obj.rect.img)
				end
			end
		end
		
		if (r > 0) then
			obj.rect.rect = display.newRoundedRect(0,0, objProps.width, objProps.height,r) 
		else
			obj.rect.rect = display.newRect( 0,0, objProps.width, objProps.height) 
		end
		
		if (st) then
			--style rectangle
			obj.rect.rect.strokeWidth = st.strokeWidth
			obj.rect.rect:setStrokeColor (st.strokeColorR, st.strokeColorG, st.strokeColorB,st.strokeColorA)
			--obj.rect.rect:setFillColor (st.fillColorR,st.fillColorG,st.fillColorB, st.fillColorA)
			self:setFillColor(obj.rect.rect, st, gf)
		end
		
		obj.rect:insert(obj.rect.rect)
		obj.view:insert(obj.rect)
		
		-------------------------------------
		-- over rectangle
		-------------------------------------
		obj.backRect = display.newGroup()
		
		-- button specific properties like text and over image
		fp = objProps.btnProps
		
		-- fill rectangle with color or texture (default)
		if (fp) then
			st = fp.styleProps
			if (fp.fillType == 4 and fp.fillAssetName ~= '') then
				xScale = (objProps.width / assets[fp.fillAssetName].width)
				yScale = (objProps.height / assets[fp.fillAssetName].height)
				obj.backRect.img = self:createObjectFromAsset(fp.fillAssetName, assets, 0,0, xScale,yScale,nil,false)		
				if (obj.backRect.img) then
					obj.backRect:insert(obj.backRect.img)
				end
			end
		end
		
		--draw over rectangle
		if (r > 0) then
			obj.backRect.rect = display.newRoundedRect(0,0, objProps.width, objProps.height,r) 
		else
			obj.backRect.rect = display.newRect( 0,0, objProps.width, objProps.height) 
		end
		
		--style rectangle
		obj.backRect.rect.strokeWidth = st.strokeWidth
		obj.backRect.rect:setStrokeColor (st.strokeColorR, st.strokeColorG, st.strokeColorB,st.strokeColorA)
		--obj.backRect.rect:setFillColor (st.fillColorR,st.fillColorG,st.fillColorB, st.fillColorA)
		self:setFillColor(obj.backRect.rect, st, gf)

		obj.backRect.alpha = 0
		
		obj.backRect:insert(obj.backRect.rect)
		obj.view:insert(obj.backRect)

		if (objProps.textProps) then
			--default to centre text for now
			local x,y = 0,0
			obj.text = display.newText( objProps.textProps.text,x,y,objProps.textProps.font,objProps.textProps.size)
			obj.text.anchorX = 0.5
			obj.text.anchorY = 0.5
			obj.view:insert(obj.text)
			
			if (obj.text and objProps.styleProps) then
				obj.text.strokeWidth = st.strokeWidth
				obj.text:setFillColor (fp.textColorR,fp.textColorG, fp.textColorB, fp.textColorA)
			end
		end
		
		if 	(obj.view) then
			-- if params.preventTap then
				-- function button:tap(event)
					-- return true
				-- end
				-- button:addEventListener('tap', button)
			-- end

			-- set button to active (meaning, can be pushed)
			obj.isActive = true

			-- If it's a switch, state 0 is off, 1 - on.
			obj.state = 0
			obj.isSwitch = false 
			obj.overAlpha = 1
			obj.defaultAlpha = 1
			
			-- if params.switch then
				-- button.isSwitch = true
			-- end
			
			function obj:touch (event)
				local result = true
				local onEvent = self.onEvent
				--print (obj.name)
				if onEvent then
					onEvent(event)
				end

				if self.isActive then
					local onPress = self.onPress
					local onMove = self.onMove
					local onRelease = self.onRelease
					local onCancel = self.onCancel

					local phase = event.phase
					if phase == 'began' then
						self.backRect.alpha = 1 --self.overAlpha
						self.rect.alpha = 0 --self.overAlpha
						if onPress then
							result = onPress(event)
						end
						-- Subsequent touch events will target button even if they are outside the stageBounds of button
						display.getCurrentStage():setFocus(self.view, event.id)
						self.isFocus = true
					elseif self.isFocus then
						local bounds = self.view.contentBounds
						local x, y = event.x,event.y
						local isWithinBounds = bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
						
						if phase == 'moved' then
							if isWithinBounds or unBounded then
								-- The rollover image should only be visible while the finger is within button's stageBounds
								self.backRect.alpha = 1
								self.rect.alpha = 0
							else
								self.backRect.alpha = 0
								self.rect.alpha = 1
								if onCancel then
									result = onCancel(event)
								end
							end
							if onMove then
								result = onMove(event)
							end
							--print ("onMove", self.name)
						elseif phase == 'ended' or phase == 'cancelled' then
							self.backRect.alpha = 0 --self.defaultAlpha
							self.rect.alpha = 1 --self.overAlpha
							if phase == 'ended' then
								-- Only consider this a "click" if the user lifts their finger inside button's stageBounds
								if isWithinBounds or unBounded then
									if onRelease then
										if self.isSwitch then
											self:toggle()
										end
										result = onRelease(event)
									end
									--print ("onRelease", self.name)
								end
							elseif phase == 'cancelled' then
								if onCancel then
									result = onCancel(event)
								end
								--print ("onCancel", self.name)
							end
							-- Allow touch events to be sent normally to the objects they "hit"
							display.getCurrentStage():setFocus(self.view, nil)
							self.isFocus = false
						end
					end
				else
					if self._onInactive and event.phase == 'began' then
						result = self._onInactive(event)
					end
				end
				
				return result
			end

			obj.view:addEventListener('touch', obj)

			function obj:disable ()
				self.alpha = 0.8
				self.isActive = false
			end

			function obj:enable ()
				self.alpha = 1
				self.isActive = true
			end

			self:applyPhysics(obj.view, objProps.physics, objProps.xScale, objProps.yScale)
			
		end

	-----------------------------------------------------
	elseif (objProps.objType == 'LDObjectJoint') then
	-----------------------------------------------------
		obj = {}
		obj.view = nil 

		if (objProps.jointProps) then
			local jt = objProps.jointProps
			
			local function findObj(layer, objName)
				local o = nil
				for k, v in pairs (layer.objects) do
					if objName == v.name then
						o = v
						break
					end
				end
	
				return o
			end
			
			local src = findObj(parentGroup,jt.srcObjectName).view
			local dst = findObj(parentGroup,jt.dstObjectName).view
			
			if (self._DEBUG) then print (jt.jointType .. ' joint ', src.name,dst.name) end
			obj = {}
			obj.view = display.newGroup()
			
			-- this may need some tweaking as was unable to test all permatations.
			if (jt.jointType == 'pivot') or (jt.jointType == 'friction') then
				obj.view.joint = physics.newJoint(jt.jointType,src,dst,jt.anchorA.x,jt.anchorA.y)
			elseif (jt.jointType == 'distance') or (jt.jointType == 'rope') then
				obj.view.joint = physics.newJoint(jt.jointType,src,dst,jt.anchorA.x,jt.anchorA.y,jt.anchorB.x,jt.anchorB.y)
			elseif (jt.jointType == 'piston') or (jt.jointType == 'wheel') then
				obj.view.joint = physics.newJoint(jt.jointType,src,dst,jt.anchorA.x,jt.anchorA.y,jt.paramA,jt.paramB)				
			end
			
			if (obj.view.joint) then
				obj.view.joint.motorSpeed = (jt.motorSpeed or 0)
				obj.view.joint.isLimitEnabled = jt.limitedEnabled or false
				obj.view.joint.isMotorEnabled = jt.motorEnabled or false
				if (jt.limit1 and jt.limit2 and jt.limitEnabled) then obj.view.joint:setRotationLimits(jt.limit1,jt.limit2) end
			end
		end
	end
	
	-- apply general properties
	if (obj) then
		obj.name = objProps.name
		obj.class = objProps.class or ''
		obj.layerName = parentGroup.name
		obj.markX, obj.markY = 0,0
		obj.ldType = objProps.objType
		
		if (objProps.followPathProps) then
			obj.followPathProps = objProps.followPathProps
		end
	
		if (obj.view) then
			obj.view.name = obj.name
		
			obj.view.class = obj.class -- duplicate so can check against collisions
		
			if (objProps.objType ~= 'LDObjectJoint') then
				if (objProps.isVisible == nil) then
					objProps.isVisible = true
				end
				
				obj.view.isVisible = objProps.isVisible
				
				-- add object to layer view
				parentGroup.view:insert(obj.view)
				
			end
			
			if (objProps.objType == 'LDObjectBezier') or (objProps.objType == 'LDObjectPath') or (objProps.objType == 'LDObjectJoint') then
				-- skip for now
			else		
				obj.view.anchorX = objProps.anchorX
				obj.view.anchorY = objProps.anchorY
				obj.view.x = objProps.x
				obj.view.y = objProps.y
				obj.markX = obj.view.x    -- store x location of object        
				obj.markY = obj.view.y    -- store y location of object	    
				
				obj.view.blendMode = objProps.blendMode
				obj.view.alpha = objProps.alpha or 1 
				
				if (objProps.rotation) then
					obj.view.rotation = objProps.rotation
				end
				
				obj.originalRotation = obj.view.rotation 
				
				-----------------------
				-- add helper functions
				-----------------------
				
				-- this adds a basic follow path routine to each object - rewrite to meet your own needs
				-- pathParam.rebound = bool		: true = rebound (switch direction) at end/start of path
				-- pathParam.direction = int	: 1 = forward, -1 backwards
				-- pathParam.delay = int		: speed - higher means more delay
				-- pathParam.repeats = int		: -1 = forever, 0 = no repeat, n = repeat n times. 
				-- pathParam.rotate = bool		: true = rotate according to angle between points
				-- pathParams.xFlip = bool		: true = flip object on x axis at end of path.
				-- pathParams.yFlip = bool		: true = flip object on y axis at end of path.
				--------------------------
				function obj:pathReached()
				--------------------------
					local pathCompleted = false 
					
					obj.currentPath = obj.currentPath + (obj.pathParams.direction * obj.fpath.inc)
					obj.destPath = obj.currentPath + (obj.pathParams.direction * obj.fpath.inc)
					obj.pathParams.elapsed = 0

					if (obj.pathParams.firstTime == false) then
						if (obj.currentPath <= obj.fpath.inc) then
							pathCompleted = true
							--if self._DEBUG then print ("start of path") end
							if (obj.pathParams.repeats < 0 or obj.pathParams.repeats > 0 ) then
								obj.pathParams.repeats = obj.pathParams.repeats - 1
							
								if (obj.pathParams.rebound) then
									
									obj.pathParams.direction = obj.pathParams.direction * -1
									obj.currentPath = obj.fpath.inc
									obj.destPath = obj.currentPath + obj.fpath.inc

									if (obj.pathParams.xFlip) then
										obj.view.xScale = obj.view.xScale * -1
									end
									if (obj.pathParams.yFlip) then
										obj.view.yScale = obj.view.yScale * -1
									end
									
								else
									obj.currentPath = obj.fpath.maxPoints
									obj.destPath = obj.currentPath-obj.fpath.inc
								end
							else
								obj.currentPath = 0 -- stop						
							end
						elseif (obj.currentPath > obj.fpath.maxPoints ) then
							--if self._DEBUG then print ("end of path" ) end
							pathCompleted = true 
							if (obj.pathParams.repeats < 0 or obj.pathParams.repeats > 0 ) then
								obj.pathParams.repeats = obj.pathParams.repeats - 1

								if (obj.pathParams.rebound) then
									--print ("rebound")
									obj.pathParams.direction = obj.pathParams.direction * -1
									obj.currentPath = obj.fpath.maxPoints + obj.fpath.inc
									obj.destPath = obj.currentPath - obj.fpath.inc

									if (obj.pathParams.xFlip) then
										obj.view.xScale = obj.view.xScale * -1
									end
									if (obj.pathParams.yFlip) then
										obj.view.yScale = obj.view.yScale * -1
									end
								else
									obj.currentPath = obj.fpath.inc
									obj.destPath = obj.currentPath + obj.currentPath
								end
							else
								obj.currentPath = 0 -- stop
							end
						end
					end -- first time

					
					if (obj.currentPath > 0 and (obj.currentPath <= obj.fpath.maxPoints)) then
						
						--if self._DEBUG then print (obj.name, obj.currentPath,obj.pathParams.direction) end
						if (obj.pathParams.rotate or false)  then
							if (obj.fpath.isBezier) then
								local startPos = {x=0,y=0}
								local endPos = {x=0,y=0}
								local x,y
							
								x, y = obj.fpath.curve(obj.currentPath)
								startPos.x, startPos.y = obj.fpath.view.x + x, obj.fpath.view.y + y
								
								x, y = obj.fpath.curve(obj.destPath)
								endPos.x, endPos.y = obj.fpath.view.x + x, obj.fpath.view.y + y
							
								obj.view.rotation = findAngle(endPos,startPos)
							else
								obj.view.rotation = findAngle({x = obj.fpath.view.x + obj.fpath.xPoints[obj.currentPath],y = obj.fpath.view.y + obj.fpath.yPoints[obj.currentPath]},{x = obj.view.x, y = obj.view.y})
							end
						end
						
						--obj.transition = transition.to( obj, { time=obj.pathParams.time,  x = obj.fpath.x + obj.fpath.xPoints[obj.currentPath], y = obj.fpath.y + obj.fpath.yPoints[obj.currentPath], transition = obj.pathParams.easing,onComplete=obj.pathReached} )
						--obj.transitions[obj.name] = obj.transition
					end
					
					if (pathCompleted)then
						--global notification
						local pathEvent = { name=LD_Helper:instance().nPathEnded, object = obj } 
						Runtime:dispatchEvent(pathEvent)
					end
				end
				
				------------------------------
				function obj:enterFrame(event)
				------------------------------
					if(nil == obj)then
						return
					end

					if(nil == obj.fpath)then
						return
					end
					
					if (obj.currentPath == 0 or obj.pathParams.paused) then
						obj.pathParams.time = event.time / 1000
						return
					end
					
					if (obj.pathParams.firstTime) then
						obj.pathParams.time = event.time / 1000
						obj.pathParams.firstTime = false
					end
									
					local startPos = {x=0,y=0}
					local endPos = {x=0,y=0}
					local x,y

					if (obj.fpath.isBezier) then
						x, y = obj.fpath.curve(obj.currentPath)
						startPos.x, startPos.y = obj.fpath.view.x + x, obj.fpath.view.y + y
						
						x, y = obj.fpath.curve(obj.destPath)
						endPos.x, endPos.y = obj.fpath.view.x + x, obj.fpath.view.y + y
					else
						startPos = {x = obj.fpath.view.x + obj.fpath.xPoints[obj.currentPath], y = obj.fpath.view.y + obj.fpath.yPoints[obj.currentPath]}
						endPos = {x = obj.fpath.view.x + obj.fpath.xPoints[obj.destPath],y = obj.fpath.view.y + obj.fpath.yPoints[obj.destPath ]}
					end
					
					local t
					if (obj.pathParams.delay == 0) then
						t = 1
					else
						t = MIN(1.0, obj.pathParams.elapsed / obj.pathParams.interval)
					end
					
					local deltaP = {x = endPos.x - startPos.x, y = endPos.y - startPos.y}

					-- set new sprite position on path
					local newPos = {x = startPos.x + deltaP.x * t, 
									y = startPos.y + deltaP.y * t}
							
					
					obj.view.x = newPos.x
					obj.view.y = newPos.y

					if (0.001 > math.abs(endPos.x-obj.view.x)) and (0.001 > math.abs(endPos.y-obj.view.y)) then
						--print ("path reached")
						obj:pathReached()
					end
					
					obj.pathParams.elapsed  = obj.pathParams.elapsed + (event.time/1000 - obj.pathParams.time)
					obj.pathParams.time 	  = event.time/1000 

				end
				
				------------------------
				function obj:resetPath()
				------------------------
					local _params = {}
					local params = obj.fpath.params -- original params
					_params.delay = params.delay or 1
					_params.repeats = params.repeats or 0
					_params.direction = params.direction or 1
					_params.rotate = params.rotate or false
					_params.rebound = params.rebound or false
					_params.xFlip = params.xFlip or false
					_params.yFlip = params.yFlip or false
					
					obj.pathParams = _params
									
					obj.destPath = 1
					obj.pathParams.paused = false
					obj.pathParams.firstTime = true
					obj.pathParams.elapsed=1
					obj.pathParams.interval =  params.delay /(#obj.fpath.xPoints+1)
					obj.view.xScale = params.xScale
					obj.view.yScale = params.yScale

					if (obj.fpath.isBezier) then
						obj.fpath.maxPoints = 1.001
						obj.fpath.inc = 0.01
						if (params.direction ==1) then
							obj.currentPath = 0.00
						else
							obj.currentPath = obj.fpath.maxPoints + 0.01
						end
					else
						obj.fpath.inc = 1
						obj.fpath.maxPoints = #obj.fpath.xPoints-1
						
						if (params.direction == 1) then
							obj.currentPath = 0 --first point -1
						else
							obj.currentPath = obj.fpath.maxPoints + 1 --last point +1
						end
					end

					obj:pathReached() -- start 

				end
				
				-------------------------------------
				function obj:followPath(path, params)
				-------------------------------------
					obj.fpath = path
					-- store original scale factor incase of flip
					params.xScale = obj.view.xScale
					params.yScale = obj.view.yScale
					
					obj.fpath.params = params
													
					-- if (self.transition) then
						-- transition.cancel(self.transition)
					-- end
					obj:resetPath() -- init local params
					
					if self._DEBUG then print (obj.name .. " will follow path " .. path.name) end
					
					if (LD_Helper:instance().listeners[obj.name]) then
						Runtime:removeEventListener(LD_Helper:instance().listeners[obj.name].name,obj)
					else
						LD_Helper:instance().listeners[obj.name]={}
					end
					
					Runtime:addEventListener( "enterFrame", obj )
					local e = {name = 'enterFrame', object = obj}
					
					LD_Helper:instance().listeners[obj.name] = e
					
				end

				-- add a drag event
				if (objProps.enableDrag or false) == true then
					function obj.view:touch( event )    
						
						if event.phase == "began" then
							obj.markX = obj.view.x    -- store x location of object        
							obj.markY = obj.view.y    -- store y location of object	    
						elseif event.phase == "moved" then	        
							local x = (event.x - event.xStart) + obj.markX        
							local y = (event.y - event.yStart) + obj.markY                
							obj.view.x, obj.view.y = x, y    -- move object based on calculations above    
						end        
						return true
					end ------------------------------------------------
					
					obj.view:addEventListener("touch", obj.view)
				end
				
				-- add additonal behavor functions here or add them to your template
				
				--parent:insert(obj)
				
			end
			
			-- Events
			for k, v in pairs (self.eventHandlers) do
				if self._DEBUG then print (k) end
				obj:addEventListener(k,v)
			end
		end
		
		-- add object to layer table
		tInsert(parentGroup.objects,obj)	

		function obj:delete()
			Runtime:removeEventListener( "enterFrame", obj )
			if (obj.ldType == 'LDObjectJoint') then
				display.remove( obj.view.joint )
			end			
			
			if (obj.view) then
				display.remove( obj.view )
				--print ("delete",obj.name)
				if (obj) and (obj.ldType ~= 'LDObjectJoint') then
					obj.view:removeSelf()
				end
			end
		end
		
	end
		
	return obj
end -- createObject 

-----------------------------------------------------------------
--  PARALLAX - helps with limit checking and/or repeated layers
-----------------------------------------------------------------
function LD_Helper:limitsHelper( level, layer, obj, dx, dy )
-----------------------------------------------------------------
	local contentSize = {width = obj.view.anchorX * obj.view.contentWidth , height= obj.view.anchorY * obj.view.contentHeight}
	
	-- may have to consider rotated sprites at some point --	
	if(nil == contentSize.width or nil == contentSize.height)then
		return
	end
		
	if layer.repeated then	
		local wrap = false
		
		-- x
		if (dx > 0) and (obj.view.x + contentSize.width  <= 0) then
			--wrap left to right
			local difX = obj.view.x + contentSize.width 
			obj.view.x = (self.contentWidth * layer.pages.right) - (contentSize.width ) + difX
			wrap = true			
		elseif (dx < 0 and obj.view.x > 0) and (obj.view.x - contentSize.width ) >= (self.contentWidth * (layer.pages.right -1)) then
			--wrap right to left
			local difX = (obj.view.x - (contentSize.width )) - (LD_Helper:instance().contentWidth  * (layer.pages.right -1))
			obj.view.x = -(self.contentWidth - contentSize.width)  + difX
			wrap = true
		end
		
		-- y	
		if (dy > 0) and (obj.view.y + contentSize.height  <= 0) then
			-- wrap bottom to top
			local difY = obj.view.y + contentSize.height 
			obj.view.y = (self.contentHeight * layer.pages.top) - (contentSize.height ) + difY
			wrap = true			
		elseif (dy < 0) and (obj.view.y - (contentSize.height ) >= (self.contentHeight * layer.pages.top) )then
			-- wrap top to bottom
			local difY = obj.view.y - (contentSize.height ) - (self.contentHeight * layer.pages.top)
			obj.view.y = -(contentSize.height ) - difY
			wrap = true
		end
		
		--dispatch wrap event
		if (wrap) then
			local wrapEvent = { name=self.nParallaxObjectWrap, object = layer, wrapObject = obj } 
			Runtime:dispatchEvent(wrapEvent)		
		end
	else
		-- no repeat so check cull Level and see if we can delete object if moved off screen
		local del = false 
		
		if (layer.cullingMethod == 2) then -- destroy
			-- x
			if (dx > 0) and (obj.view.x + contentSize.width  <= 0) then
				del = true			
			elseif (dx < 0 and obj.view.x > 0) and (obj.view.x - contentSize.width ) >= (self.contentWidth * (layer.pages.right -1)) then
				del = true
			end
			
			-- y	
			if (dy > 0) and (obj.view.y + contentSize.height  <= 0) then
				del = true			
			elseif (dy < 0) and (obj.view.y - (contentSize.height ) >= (self.contentHeight * layer.pages.top) )then
				del = true
			end
		
			if (del) then
				table.remove(layer.objects,idx)
				obj:delete()
			end
		end -- cullingMethod = 2
		
	end -- repeated

end -- end helper		

----------------------------------------
function LD_Helper:createParallax(level)
----------------------------------------
	if (level.parallaxEnabled or false) == true then
		level.cameraPos = {x = 0, y = 0}
		level.cameraFocus = nil
		level.isTracking = false 
		level.cameraBounds = nil
		
		---------------------------------------------------------
		local function checkCameraBounds(_dx, _dy)
		---------------------------------------------------------
			local pos = level.cameraPos
			local bounds = level.cameraBounds
			local dx, dy = _dx,_dy
			local tx, ty =0,0
			
			if (bounds == nil) then
				return dx, dy
			end
			
			if (level.isTracking and level.cameraFocus) then
				tx,ty = level.cameraFocus.tx, level.cameraFocus.ty
			end
			
			--bounds check
			if (dx ~= 0 or dy ~= 0) then
				if (dx < 0 and pos.x + dx < bounds.xMin ) then
					dx = 0
					if (level.isTracking and level.cameraFocus) then
						level.cameraFocus.x = tx
					end
				end
				if (dx > 0 and pos.x + dx > bounds.xMax ) then
					dx = 0
					if (level.isTracking and level.cameraFocus) then
						level.cameraFocus.x = tx
					end
				end

				if (dy < 0 and pos.y + dy < bounds.yMin ) then
					dy = 0
					if (level.isTracking and level.cameraFocus) then
						level.cameraFocus.y = ty
					end
				end

				if (dy > 0 and pos.y + dy > bounds.yMax ) then
					dy = 0
					if (level.isTracking and level.cameraFocus) then
						level.cameraFocus.y = ty
					end
				end
			end
			
			return dx, dy
			
		end
		
		---------------------------------------------------------
		--  Move the scence by delta
		-- @param dx Number of pixels to move in the X direction
		-- @param dy Number of pixels to move in the Y direction
		---------------------------------------------------------
		function level:move( dx, dy)
		
			local layers = level.layers
			local cameraPos = level.cameraPos
			local dt = level.parallaxDamping
			
			dx, dy = checkCameraBounds(dx, dy)
			
			if (dx ==0 and dy ==0) then
				return
			end
			
			cameraPos.x = cameraPos.x + (dx * dt)
			cameraPos.y = cameraPos.y + (dy * dt)
			
			-- iterate through the layers
			for index, layer in ipairs( layers ) do
				if (layer.speed.x ~= 0 or layer.speed.y ~= 0 ) then
				
					if level.parallaxInfinite then
					
						-- iterate through objects and move them
						local objects = layer.objects
						for index2, obj in ipairs( objects ) do
							local x,y
							x = ((dx * layer.speed.x) * dt)
							y = ((dy * layer.speed.y) * dt)
							obj.view:translate(-x,-y)	
							LD_Helper:instance():limitsHelper( level, layer, obj , x , y)
						end -- for each obj
					else
						-- just move layers in camera mode (much faster but no repeat allowed)
						layer.offset.x = layer.offset.x - ((dx * layer.speed.x) * dt)
						layer.offset.y = layer.offset.y - ((dy * layer.speed.y) * dt)
						
						local xPos = layer.speed.x + layer.offset.x
						local yPos = layer.speed.y + layer.offset.y
						
						layer.view.x = xPos
						layer.view.y = yPos
					end -- infinite
				end -- layer speed
			end -- for each layer
			--print ("END MOVE")
		
		end
		
		---------------------------------------------
		--  Move camera position
		-- @param x The new X position of the Camera.
		-- @param y The new Y position of the Camera.
		--------------------------------------------
		function level:moveCamera(x,y)
			local dx,dy = 0,0
			
			dx = x - level.cameraPos.x
			dy = y - level.cameraPos.y

			level:move(dx,dy) --redraw
		end
		
		---------------------------------------------------------------------------------------
		-- Return camera position (rounded)
		---------------------------------------------------------------------------------------
		function level:getCameraPos()
			local pos = {x = round(level.cameraPos.x), y = round(level.cameraPos.y)}
			return pos
		end
		
		---------------------------------------------
		--  Track focus object position
		-- @param x The new X position of the Camera.
		-- @param y The new Y position of the Camera.
		--------------------------------------------
		local function trackFocus()
			if (level.cameraFocus == nil) then
				return false
			end
			
			local dx,dy = 0,0
			local x,y = level.cameraFocus.x, level.cameraFocus.y
			local tx,ty = level.cameraFocus.tx, level.cameraFocus.ty
			
			if (level.trackX) then
				dx = x - tx --level.cameraPos.x
			end
			
			if (level.trackY) then
				dy = y - ty --level.cameraPos.y
			end

			level:move(dx,dy) --redraw
			
			level.cameraFocus.tx = level.cameraFocus.x
			level.cameraFocus.ty = level.cameraFocus.y

		end
		
		---------------------------------------------------------------------------------------
		--  Enable/disable tracking
		-- @param enable Enabled/disable tracking
		---------------------------------------------------------------------------------------
		function level:trackEnabled(enable)
			local lName = "@tracking"
			
			if (level.isTracking) then 
				if (LD_Helper:instance().listeners[lName]) then
					Runtime:removeEventListener("enterFrame", level.trackFocus)
				else
					LD_Helper:instance().listeners[lName]={}
				end
				level.isTracking = false 
			end
			
			if (enable) then
				if (level.cameraFocus == nil) then
					print ("Cannot start tracking - Please assign an object first")
					return false
				end
				
				level.cameraFocus.tx = level.cameraFocus.x
				level.cameraFocus.ty = level.cameraFocus.y
				
				level.isTracking = true
				
				Runtime:addEventListener("enterFrame", trackFocus)			
				local e = {name = 'enterFrame', object = trackFocus}
				
				LD_Helper:instance().listeners[lName] = e
			end
		end
		
		---------------------------------------------------------------------------------------
		-- Slides the Object to a new position.
		-- @param obj The object to focus the camera on
		-- @param trackX, set as false to disable x axis tracking
		-- @param trackY, set as false to disable y axis tracking
		---------------------------------------------------------------------------------------
		function level:setCameraFocus(obj, trackX, trackY)
			level.cameraFocus = obj
			level.trackX = true
			level.trackY = true
			
			if (trackX ~= nil) then
				level.trackX = trackX
			end
			
			if (trackY ~= nil) then
				level.trackY = trackY
			end
		end
		
		---------------------------------------------------------------------------------------
		--- Slides the Object to a new position.
		-- @param x The new X position of the Camera.
		-- @param y The new Y position of the Camera.
		-- @param slideTime The time it will take to slide the Object to the new position.
		-- @param onCompleteHandler Event handler to be called on movement completion. Optional.
		---------------------------------------------------------------------------------------
		function level:slideCameraToPosition(x, y, slideTime, easingType, onCompleteHandler)
			local camera = {xPos = level.cameraPos.x, yPos=level.cameraPos.y}
			local _x = x
			local _y = y
			local _slideTime = slideTime
			local _onCompleteHandler = onCompleteHandler
			local round = math.round 
			local _easing = easingType or easing.linear
			
			level.onSlideTransitionUpdate = function(event)
				level:moveCamera(round(camera.xPos), round(camera.yPos))
			end
			
			local onSlideComplete = function(event)
			
				if _onCompleteHandler then
					_onCompleteHandler(event)
				end
				
				Runtime:removeEventListener("enterFrame", level.onSlideTransitionUpdate)
			end
			
			if (level.slideTransition) then
				transition.cancel(level.slideTransition)
				Runtime:removeEventListener("enterFrame", level.onSlideTransitionUpdate)
				level.slideTransition = nil
			end
			
			Runtime:addEventListener("enterFrame", level.onSlideTransitionUpdate)
			
			level.slideTransition = transition.to( camera, {time=_slideTime or 1000, transition=_easing,xPos=_x, yPos=_y, onComplete=onSlideComplete})
		end
		
		----------------------------------------------------------
		--  setCameraBounds
		-- @param _xMin The left outer bounds
		-- @param _yMin The top outer bounds
		-- @param _xMax The right outer bounds
		-- @param _yMax The bottom outer bounds
		----------------------------------------------------------
		function level:setCameraBounds(_xMin, _yMin, _xMax, _yMax)
			level.cameraBounds = nil
			
			if (_xMin and _yMin and _xMax and _yMax) then
				level.cameraBounds = {xMin = _xMin, yMin = _yMin, xMax = _xMax, yMax = _yMax}
			end
		end
		
		-- set basic boundary check
		if (level.parallaxInfinite == false) then
			level:setCameraBounds(0, 0, (level.canvasWidth - self.contentWidth), (level.canvasHeight - self.contentHeight))
		end

	end
	
end -- createParallax

--------------------------------------------------
function LD_Helper:insertLayer(parentGroup, layer)
--------------------------------------------------
	local page = 0 
		
	tInsert(parentGroup.layers,layer)

	if parentGroup.parallaxEnabled then
		layer.pages = {right = 1, left = 0, top = 0, bottom = 0} 
		layer.offset = {x = layer.view.x, y = layer.view.y }
		
		local objects = layer.objects

		-- calculate how many pages (screen widths) each layer spans
		for index2, obj in ipairs( objects ) do
			if (obj.view) then
				page = toInt((obj.view.x or 0) / self.contentWidth)
				
				if (layer.pages.right <= page)then
					layer.pages.right = page + 1
				end
				
				if (layer.pages.left >= page)then
					layer.pages.left = page - 1
				end

				page = toInt((obj.view.y or 0) / self.contentHeight)
				
				if (layer.pages.top <= page) then
					layer.pages.top = page + 1
				end
				
				if (layer.pages.bottom >= page)then
					layer.pages.bottom = page - 1
				end
			end
		end
		if self._DEBUG then print (layer.name, layer.pages.right, layer.pages.left, layer.pages.top, layer.pages.bottom) end
	end
	
	if (application.LevelDirectorSettings.viewGroup ~= nil) then
		application.LevelDirectorSettings.viewGroup:insert(layer.view)
	else		
		parentGroup.view:insert(layer.view)
	end
	
end -- insertLayer

----------------------------
function LD_Helper:cleanUp(retainSpriteSheets)
----------------------------
	local keep = (retainSpriteSheets or false)

	-- clear spritesheets (this could be removed if spritesheets are shared across levels)
	if (keep == false) then
		self.spriteSheets = {}
	end
	
	-- remove any transitions
	local k, v

    for k,v in pairs(self.transitions) do
		if self._DEBUG then print ("transition " .. k .. " cancelled") end
        transition.cancel( v )
        v = nil; k = nil
    end
	
	self.transitions = {}

	-- remove any listeners

    for k,v in pairs(self.listeners) do
		if self._DEBUG then print ("listener " .. k .. " cancelled") end 
        Runtime:removeEventListener(v.name,v.object)
        v = nil; k = nil
    end
	
	self.listeners = {}
		
end
