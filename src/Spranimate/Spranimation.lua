local assertType = require(script.Parent.TypeChecker).AssertType


local Spranimation = {}

Spranimation.__index = Spranimation
Spranimation.writableProps = {"Looped", "Priority"}


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
    local totalFrames = 0
    for _, segment in pairs(segmentTable) do
        totalLength += segment.Length
        totalFrames += math.abs(segment.EndFrame - segment.StartFrame) + 1
    end
    self.Length = totalLength
    self.FrameCount = totalFrames

    return setmetatable({}, {
        __index = self,
        __newindex = function(_, index, value)
            if not table.find(self.writableProps, index) then
                error("cannot write to " .. index .. " to Spranimation")
            end

            self[index] = value
        end,
    })
end


return Spranimation