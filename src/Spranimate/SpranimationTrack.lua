local FastWait = require(script.Parent.FastWait)
local Signal = require(script.Parent.Signal)


local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack

local writableProps = {"Looped", "Priority", "TimePosition"}


function SpranimationTrack.new(Spranimation, Spranimator)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation
    self._spranimator = Spranimator -- just used for setting the frame, so can be private

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Length = Spranimation.Length
    self.IsPlaying = false
    self.Speed = 1

    self.CurrentFrame = Spranimation._segmentTable[1].StartFrame
    self.CurrentSegmentIndex = 1

    self._destroyed = false
    self._playThread = self:_makeSpranimationCoroutine()
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


-- a function that sets the animation to the next frame in its sequence, respecting segments
function SpranimationTrack:AdvanceFrame()
    local segTable = self.Spranimation._segmentTable
    local segment = segTable[self.CurrentSegmentIndex]

    -- if we're at the end of the segment, we have to jump to the next one
    if self.CurrentFrame == segment.EndFrame then
        -- get to the next segment using mods to loop back to the first if needed
        self.CurrentSegmentIndex = (self.CurrentSegmentIndex % #segTable) + 1
        self.CurrentFrame = segment.StartFrame

        -- if the user has a signal attatched to the loading of the new segment, it should fire
        local segSignal = self._segmentSignalTable[segment.Name]
        if segSignal then
            segSignal:Fire(segment.Name)
        end
    else
        self.CurrentFrame += 1
    end

    self._spranimator:SetFrame(self.CurrentFrame)
end


function SpranimationTrack:_makeSpranimationCoroutine()
    return coroutine.wrap(function()
        -- coroutine will only complete upon the instance being destroyed
        while not self._destroyed do

            if not self.IsPlaying then
                -- pause when not playing
                coroutine.yield()
            end

            -- set next frame
            self:AdvanceFrame()

            -- wait for next frame (timing must be >=1/60 of a second)
            local segTable = self.Spranimation._segmentTable
            local segment = segTable[self.CurrentSegmentIndex]
            local framesInSegment = segment.EndFrame - segment.StartFrame + 1 -- inclusive countining :)
            FastWait(segment.Length/framesInSegment/self.Speed) -- TODO a negative speed should play the animation backwards

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