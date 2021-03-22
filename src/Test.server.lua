local sprite = script.Parent

local Spranimate = require(game:GetService("ReplicatedStorage"):WaitForChild("Spranimate"))

local Spranimator = Spranimate.Spranimator
local Spranimation = Spranimate.Spranimation

local controller = Spranimator.new(script.Parent)

local runAnim = Spranimation.new({
	{
		StartFrame = 4,
		EndFrame = 12,
		Length = 0.6,
	}
})


controller:LoadSpranimation(runAnim):Play()