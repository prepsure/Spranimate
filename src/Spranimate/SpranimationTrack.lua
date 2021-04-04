local modules = script.Parent.Modules
local Janitor = require(modules.Janitor)
local Signal = require(modules.Signal)


local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack
SpranimationTrack.ClassName = "SpranimationTrack"


---------- constructor ----------


--- constructs a new SpranimationTrack
-- @param Spranimation <Spranimation> - the Spranimation the SpranimationTrack should draw data from

function SpranimationTrack.new(Spranimation)

    local self = setmetatable({}, SpranimationTrack)

    self._janitor = Janitor.new()

    -- public
    self.Name = self.ClassName
    self.Spranimation = Spranimation

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Speed = 1
    self.Length = Spranimation.Length
    self.FrameCount = Spranimation.FrameCount

    self.IsPlaying = false
    self.TimePosition = 0
    self.CurrentFrame = Spranimation.FirstFrame

    self.FlipX = false
    self.FlipY = false

    self.DidLoop = self._janitor:Add( Signal.new() )
    self.FrameReached = self._janitor:Add( Signal.new() )
    self.SegmentReached = self._janitor:Add( Signal.new() )
    self.Stopped = self._janitor:Add( Signal.new() )

    -- private
    self._currentSegmentIndex = 1
    self._destroyed = false
    self._signalTable = {}

    return self
end


---------- private functions ----------


function SpranimationTrack:_getCurrentSegment()
    return self.Spranimation._segmentTable[self._currentSegmentIndex]
end


function SpranimationTrack:_getReachedSignal(index)
    -- check if a signal for that name already exists and return it if so
    if self._signalTable[index] then
        return self._signalTable[index]
    end

    -- create new signal with the index
    local newSignal = self._janitor:Add( Signal.new() )
    self._signalTable[index] = newSignal
    return newSignal
end


---------- public functions ----------


--- sets the animation to the next frame in its sequence, respecting segments
-- @param frames <integer> - the number of frames to advance forward

function SpranimationTrack:AdvanceFrame(frames)
    local segment = self:_getCurrentSegment()

    -- if first frame, fire DidLoop
    if self.CurrentFrame == self.Spranimation.FirstFrame and
       self:_getCurrentSegment() == self.Spranimation._segmentTable[1]
    then
        self.DidLoop:Fire()
    end

    -- loop for each frame that needs to be counted
    frames = frames or 1
    for _ = 1, frames do

        -- if we're at the end of the segment, we have to jump to the next one
        if self.CurrentFrame == segment.EndFrame then
            -- get to the next segment using mods to loop back to the first if needed
            segment = (self._currentSegmentIndex % #self.Spranimation._segmentTable) + 1
            self._currentSegmentIndex = segment
            self.CurrentFrame = self:_getCurrentSegment().StartFrame

            -- fire SegmentReached
            self.SegmentReached:Fire(segment.Name)

            -- if a signal is attatched to the loading of the new segment, it should fire
            local segSignal = self._signalTable[segment.Name]
            if segSignal then
                segSignal:Fire(segment.Name)
            end

        else
            -- math.sign accounts for frames going in reverse
            self.CurrentFrame += math.sign(segment.EndFrame - segment.StartFrame)

            -- fire FrameReached
            self.FrameReached:Fire(self.CurrentFrame)

            -- if a signal is attatched to the loading of the frame, it should fire
            local frameSignal = self._signalTable[self.CurrentFrame]
            if frameSignal then
                frameSignal:Fire(self.CurrentFrame)
            end
        end

        -- check if this is the last frame
        if self.CurrentFrame == self.Spranimation.LastFrame and
           self:_getCurrentSegment() == self.Spranimation._segmentTable[#self.Spranimation._segmentTable]
        then
            -- stop playing if not Looped
            if not self.Looped then
                self:Pause()
            end
        end

    end
end


--- gets a signal for a specific segment name
-- @param  segmentName   <string> - the name of the segment that the signal should fire for
-- @return segmentSignal <Signal> - a signal that will fire when the segment switches to the named segment
--                                - will fire for multiple segments with the same name

SpranimationTrack.GetSegmentReachedSignal = SpranimationTrack._getReachedSignal


--- gets a signal for a specific frame
-- @param  frame       <integer> - the name of the frame that the signal should fire for
-- @return frameSignal <Signal>  - a signal that will fire when the animation advanced to the frame

SpranimationTrack.GetFrameReachedSignal = SpranimationTrack._getReachedSignal


--- gets the time the first segment with a name starts at
-- @param  segmentName <string> - the name of the segment to get the time for
-- @return time        <number> - the time position that the segment starts at

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


--- seeks to the frame of the given timestamp
-- @param  timePos <number> - the time to seek to
-- @return frame   <number> - the frame that was sought to

function SpranimationTrack:Seek(timePos)
    self.TimePosition = timePos
    self.CurrentFrame = self.Spranimation:GetFrameAtTime()
    return self.CurrentFrame
end


--- plays the spranimation track, starting from the current segment and frame

function SpranimationTrack:Play()
    self.IsPlaying = true
end


--- stops the spranimation track, keeping the current segment and frame

function SpranimationTrack:Pause()
    self.IsPlaying = false
end


--- stops the spranimation track, resetting the current segment and frame

function SpranimationTrack:Stop()
    self:Pause()

    self._currentSegmentIndex = 1
    self.CurrentFrame = self.Spranimation._segmentTable[1].StartFrame
    self.Stopped:Fire()
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
    self._janitor:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end


return SpranimationTrack