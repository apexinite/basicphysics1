application =
{

	content =
	{
		width =  750,
		height = 1334, 
		--scale = "letterBox", ORIGINAL FROM CORONA
		-- LINE DIRECTLY BELOW IS FROM LEVELDIRECTOR EXAMPLE1
		scale = "zoomStretch",
		fps = 60,
		
		--[[
		imageSuffix =
		{
			    ["@2x"] = 2,
		},
		--]]
	},

	LevelDirectorSettings = 
	{
		imagesSubFolder = "images",
	}
	--[[
	-- Push notifications
	notification =
	{
		iphone =
		{
			types =
			{
				"badge", "sound", "alert", "newsstand"
			}
		}
	},
	--]]    
}
