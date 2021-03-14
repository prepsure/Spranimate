local assertType = require(script.Parent.TypeChecker).AssertType


local Spranimation = {}

Spranimation.__index = Spranimation


local function giveSegmentsDefaultProps(segmentTable)
    for i, segment in pairs(segmentTable) do
        assertType(segment.Name, "string", true)
        assertType(segment.StartFrame, "number")
        assertType(segment.EndFrame, "number", true)
        assertType(segment.Length, "number")

        segment.Name = segment.Name or ("Segment" .. i)
        segment.EndFrame = segment.EndFrame or segment.StartFrame
    end

    return segmentTable
end


function Spranimation.new(segmentTable, priority, looped)
    local self = setmetatable({}, Spranimation)

    self._segmentTable = giveSegmentsDefaultProps(segmentTable)

    self.Priority = priority
    self.Looped = looped

    local totalLength = 0
    for _, segment in pairs(segmentTable) do
        totalLength += segment.Length
    end
    self.Length = totalLength

    return setmetatable( {}, {__index = self} )
end


return Spranimation