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
    self.Spranimation = Spranimation

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Speed = 1
    self.Length = Spranimation.Length
    self.IsPlaying = false
    self.TimePosition = 0
    self.CurrentFrame = Spranimation.FirstFrame

    self.FlipX = false
    self.FlipY = false

    -- private
    self._currentSegmentIndex = 1
    self._destroyed = false
    self._segmentSignalTable = {}

    return self
end


---------- private functions ----------


function SpranimationTrack:_getCurrentSegment()
    return self.Spranimation._segmentTable[self._currentSegmentIndex]
end


---------- public functions ----------


--- sets the animation to the next frame in its sequence, respecting segments
-- @param frames <integer> - the number of frames to advance forward

function SpranimationTrack:AdvanceFrame(frames)
    local segment = self:_getCurrentSegment()

    -- loop for each frame that needs to be counted
    frames = frames or 1
    for _ = 1, frames do

        -- if we're at the end of the segment, we have to jump to the next one
        if self.CurrentFrame == segment.EndFrame then
            -- get to the next segment using mods to loop back to the first if needed
            segment = (self._currentSegmentIndex % #self.Spranimation._segmentTable) + 1
            self._currentSegmentIndex = segment
            self.CurrentFrame = self:_getCurrentSegment().StartFrame

            -- if the user has a signal attatched to the loading of the new segment, it should fire
            local segSignal = self._segmentSignalTable[segment.Name]
            if segSignal then
                segSignal:Fire(segment.Name)
            end

            -- go to the next frame
            continue
        end

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
    local newSignal = self._janitor:Add( Signal.new() )
    self._segmentSignalTable[segmentName] = newSignal
    return newSignal
end


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