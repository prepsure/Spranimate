local FastWait = require(script.Parent.FastWait)
local Signal = require(script.Parent.Signal)


local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack
SpranimationTrack.ClassName = "SpranimationTrack"


---------- constructor ----------


--- constructs a new SpranimationTrack
-- @param Spranimation <Spranimation> - the Spranimation the SpranimationTrack should draw data from

function SpranimationTrack.new(Spranimation)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Length = Spranimation.Length
    self._isPlaying = false
    self.Speed = 1

    self.CurrentFrame = Spranimation._segmentTable[1].StartFrame
    self.CurrentSegmentIndex = 1

    self.FlipX = false
    self.FlipY = false

    self._destroyed = false
    self._playThread = self:_makeSpranimationCoroutine()
    self._segmentSignalTable = {}

    return self
end


---------- private functions ----------


function SpranimationTrack:_getCurrentSegment()
    return self.Spranimation._segmentTable[self.CurrentSegmentIndex]
end


function SpranimationTrack:_makeSpranimationCoroutine()
    return coroutine.wrap(function()
        repeat

            if not self._isPlaying then
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


---------- public functions ----------


--- sets the animation to the next frame in its sequence, respecting segments
-- @param frames <integer> - the number of frames to advance forward

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


--- gets a signal for a specific segment name
-- @param   segmentName   <string>  - the name of the segment that the signal should fire for
-- @return  segmentSignal <Signal>  - a signal that will fire when the segment switches to the named segment
--                                  - will fire for multiple segments with the same name

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


--- gets the time the first segment with a name starts at
-- @param  segmentName <string> - the name of the segment to get the time for
-- @return time        <number> - the time position that the segment starts at
--                              - (may not be accurate if each frame has a time not divisible by 60)

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


--- gets the playing state of the SpranimationTrack
-- @return - true if the SpranimationTrack is currently playing

function SpranimationTrack:IsPlaying()
    return self._isPlaying
end


--- plays the spranimation track, starting from the current segment and frame

function SpranimationTrack:Play()
    self._isPlaying = true
    self._playThread()
end


--- stops the spranimation track, keeping the current segment and frame

function SpranimationTrack:Pause()
    self._isPlaying = false
end


--- stops the spranimation track, resetting the current segment and frame

function SpranimationTrack:Stop()
    self:Pause()

    self.CurrentSegmentIndex = 1
    self.CurrentFrame = self.Spranimation._segmentTable[1].StartFrame
end


----------- roblox instance functions ----------


--- copies the SpranimationTrack, but not the underlying Spranimation
-- @return clone <SpranimationTrack> - the copied SpranimationTrack

function SpranimationTrack:Clone()
    return SpranimationTrack.new(self.Spranimation)
end


--- destroys the SpranimationTrack, rendering it unusable

function SpranimationTrack:Destroy()
    self._destroyed = true

    for _, signal in pairs(self._segmentSignalTable) do
        signal:Destroy()
    end
end


return SpranimationTrack