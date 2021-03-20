local assertType = require(script.Parent.TypeChecker).AssertType


local Spranimation = {}

Spranimation.__index = Spranimation

--[[
local sampleSegmentTable = {
    {
        Name = "Seg1",
        StartFrame = 1,
        EndFrame = 3,
        Length = 0.5,
    },
    {
        Name = "Seg2",
        StartFrame = 4,
        Length = 1,
    },
    {
        StartFrame = 6,
        EndFrame = 16,
        Length = 5,
    }
}
]]

local function giveSegmentsDefaultProps(segmentTable)
    for i, segment in pairs(segmentTable) do
        assertType(segment.Name, "string", true)
        assertType(segment.StartFrame, "number")
        assertType(segment.EndFrame, "number", true)
        assertType(segment.Length, "number")

        segment.Name = segment.Name or "Segment"
        segment.EndFrame = segment.EndFrame or segment.StartFrame
    end

    return segmentTable
end


function Spranimation.new(segmentTable, priority, looped)
    local self = setmetatable({}, Spranimation)

    self._segmentTable = giveSegmentsDefaultProps(segmentTable)

    self.Priority = priority or Enum.AnimationPriority.Core
    self.Looped = not not looped

    local totalLength = 0
    for _, segment in pairs(segmentTable) do
        totalLength += segment.Length
    end
    self.Length = totalLength

    return setmetatable({}, {
        __index = self,
        __newindex = function()
            error("Spranimation is read only")
        end,
    })
end


return Spranimation