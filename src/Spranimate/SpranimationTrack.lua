local FastWait = require(script.Parent.FastWait)
local Signal = require(script.Parent.Signal)


local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack
SpranimationTrack.ClassName = "SpranimationTrack"

local writableProps = {"Looped", "Priority", "TimePosition"}


function SpranimationTrack.new(Spranimation)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation

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


function SpranimationTrack:_getCurrentSegment()
    return self.Spranimation._segmentTable[self.CurrentSegmentIndex]
end


-- a function that sets the animation to the next frame in its sequence, respecting segments
function SpranimationTrack:AdvanceFrame(frames) -- TODO make work for multiple frames
    local segment = self:_getCurrentSegment()

    -- if we're at the end of the segment, we have to jump to the next one
    if self.CurrentFrame == segment.EndFrame then
        -- get to the next segment using mods to loop back to the first if needed
        local newSegmentIndex = (self.CurrentSegmentIndex % #self.Spranimation._segmentTable) + 1
        self.CurrentSegmentIndex = newSegmentIndex
        self.CurrentFrame = self:_getCurrentSegment().StartFrame

        -- if the user has a signal attatched to the loading of the new segment, it should fire
        local segSignal = self._segmentSignalTable[segment.Name]
        if segSignal then
            segSignal:Fire(segment.Name)
        end
    else
        -- math.sign accounts for frames going in reverse
        self.CurrentFrame += math.sign(segment.EndFrame - segment.StartFrame)
    end
end


function SpranimationTrack:_makeSpranimationCoroutine()
    return coroutine.wrap(function()
        repeat

            if not self.IsPlaying then
                -- pause when not playing
                coroutine.yield()
                -- refresh loop when resuming
            end

            -- coroutine will only complete upon the instance being destroyed
            if self._destroyed then
                break
            end

            -- set next frame
            self:AdvanceFrame()

            -- wait for next frame (timing must be >=1/60 of a second)
            local segment = self:_getCurrentSegment()
            local framesInSegment = math.abs(segment.EndFrame - segment.StartFrame) + 1 -- inclusive countining :)
            FastWait(segment.Length/framesInSegment/self.Speed) -- TODO a negative speed should play the animation backwards

        until self._destroyed -- todo implement not looping

    end)
end


function SpranimationTrack:GetSegmentReachedSignal(segmentName)
    -- check if a signal for that name already exists and return it if so
    if self._segmentSignalTable[segmentName] then
        return self._segmentSignalTable[segmentName]
    end

    -- create new signal with the index of segmentName
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
    self._playThread()
end


function SpranimationTrack:Pause()
    self.IsPlaying = false
end


function SpranimationTrack:Stop()
    self:Pause()

    self.CurrentSegmentIndex = 1
    self.CurrentFrame = self.Spranimation._segmentTable[1].StartFrame
end


function SpranimationTrack:Clone()
    return SpranimationTrack.new(self.Spranimation)
end


function SpranimationTrack:Destroy()
    self._destroyed = true
end


return SpranimationTrack