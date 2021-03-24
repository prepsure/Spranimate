local FastWait = require(script.Parent.FastWait)
local Signal = require(script.Parent.Signal)


local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack

local writableProps = {"Looped", "Priority", "TimePosition"}


function SpranimationTrack.new(Spranimation, Spranimator)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation
    self._spranimator = Spranimator

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Length = Spranimation.Length
    self.IsPlaying = false
    self.Speed = 1

    self.CurrentFrame = Spranimation._segmentTable[1].StartFrame
    self.CurrentSegmentIndex = 1

    self._destroyed = false
    self._playThread = self:_loopWithTimings()
    self._segmentSignalTable = {}

    return self--[[setmetatable({}, {
        __index = self,
        __newindex = function(index, value)
            if not table.find(writableProps, index) then
                error("cannot write to " .. index .. " in SpranimationTrack")
            end

            self[index] = value
        end
    })]]
end


function SpranimationTrack:AdvanceFrame()
    local segTable = self.Spranimation._segmentTable
    local segment = segTable[self.CurrentSegmentIndex]

    if self.CurrentFrame == segment.EndFrame then
        self.CurrentSegmentIndex = (self.CurrentSegmentIndex % #segTable) + 1
        self.CurrentFrame = segment.StartFrame

        local segSignal = self._segmentSignalTable[segment.Name]
        if segSignal then
            segSignal:Fire(segment.Name)
        end
    else
        self.CurrentFrame += 1
    end

    self._spranimator:SetFrame(self.CurrentFrame)
end


function SpranimationTrack:_loopWithTimings()
    return coroutine.wrap(function()
        while not self._destroyed do
            if not self.IsPlaying then
                coroutine.yield()
            end

            self:AdvanceFrame()

            local segTable = self.Spranimation._segmentTable
            local segment = segTable[self.CurrentSegmentIndex]
            local framesInSegment = segment.EndFrame - segment.StartFrame + 1
            FastWait(segment.Length/framesInSegment/self.Speed)
        end
    end)
end


function SpranimationTrack:GetSegmentReachedSignal(segmentName)
    if self._segmentSignalTable[segmentName] then
        return self._segmentSignalTable[segmentName]
    end

    local newSignal = Signal.new()
    self._segmentSignalTable[segmentName] = newSignal
    return newSignal
end


function SpranimationTrack:GetTimeOfSegment(segmentName)
    local totalTime = 0

    for index, segment in pairs(self.Spranimation._segmentTable) do
        if segment.Name == segmentName then
            return totalTime
        end

        totalTime += segment.Length
    end

    error("segment name not found in Spranimation")
end


function SpranimationTrack:Play(speed)
    self.IsPlaying = true
end


function SpranimationTrack:Stop()
    self.IsPlaying = false
end


return SpranimationTrack