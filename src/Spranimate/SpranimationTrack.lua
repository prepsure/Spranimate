local SpranimationTrack = {}

SpranimationTrack.__index = SpranimationTrack

local writableProps = {"Looped", "Priority", "TimePosition"}


function SpranimationTrack.new(Spranimation)

    local self = setmetatable({}, SpranimationTrack)

    self.Spranimation = Spranimation

    self.Looped = Spranimation.Looped
    self.Priority = Spranimation.Priority

    self.Length = Spranimation.Length
    self.IsPlaying = false
    self.Speed = 1
    self.TimePosition = 0

    return setmetatable({}, {
        __index = self,
        __newindex = function(index, value)
            if not table.find(writableProps, index) then
                error("cannot write to " .. index .. " in SpranimationTrack")
            end

            self[index] = value
        end
    })
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