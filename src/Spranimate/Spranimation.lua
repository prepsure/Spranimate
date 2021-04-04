local modules = script.Parent.Modules
local assertType = require(modules.TypeChecker).AssertType


local Spranimation = {}

Spranimation.__index = Spranimation
Spranimation.ClassName = "Spranimation"


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


local function getLengthAndFrameCount(segmentTable)
    local totalLength = 0
    local totalFrames = 0

    for _, segment in pairs(segmentTable) do
        totalLength += segment.Length
        totalFrames += math.abs(segment.EndFrame - segment.StartFrame) + 1
    end

    return totalLength, totalFrames
end


function Spranimation.new(segmentTable, priority, looped)
    local self = setmetatable({}, Spranimation)

    self._segmentTable = giveSegmentsDefaultProps(segmentTable)

    self.Name = self.ClassName

    self.Priority = priority or Enum.AnimationPriority.Core
    self.Looped = not not looped

    self.Length, self.FrameCount = getLengthAndFrameCount(self._segmentTable)
    self.FirstFrame = self._segmentTable[1].StartFrame
    self.LastFrame = self._segmentTable[#self._segmentTable].EndFrame

    return setmetatable({}, {
        __index = self,
        __newindex = function()
            error("Spranimation is readonly, modify SpranimationTrack instead", 2)
        end,
    })
end


function Spranimation:GetFrameAtTime(timePos)
    local totalTime = 0

    for i, seg in pairs(self._segmentTable) do

        if totalTime + seg.Length > timePos then
            -- abs value for sequences that go backwards, +1 for inclusive counting
            local totalFrames = math.abs(seg.EndFrame - seg.StartFrame) + 1
            local lowest = math.min(seg.StartFrame, seg.EndFrame)
            -- the equation [% of frames * length = time until target] rearranged and using floor to get a frame:
            return math.floor( (timePos - totalTime) * totalFrames / seg.Length ) + lowest
        end

        totalTime += seg.Length
    end

    warn("no frame found for time: " .. timePos .. " returning last frame")
    return self.LastFrame
end


function Spranimation:Clone()
    return Spranimation.new(self._segmentTable, self.Priority, self.Looped)
end


function Spranimation:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end


return Spranimation