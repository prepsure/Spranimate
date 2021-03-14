local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack


function SpranimationTrack.new(Spranimation)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Length = Spranimation.Length
    self.IsPlaying = false
    self.Speed = 1
    self.TimePosition = 0

    return self

end


function SpranimationTrack:AdjustSpeed(speed)

end


function SpranimationTrack:GetSegmentReachedSignal(segmentName)

end


function SpranimationTrack:GetTimeOfSegment(segmentName)

end


function SpranimationTrack:Play(speed)

end


function SpranimationTrack:Stop()

end


return SpranimationTrack