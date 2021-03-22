local FastWait = require(script.Parent.FastWait)


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
    self.TimePosition = 0

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


function SpranimationTrack:AdjustSpeed(speed)

end


function SpranimationTrack:GetSegmentReachedSignal(segmentName)

end


function SpranimationTrack:GetTimeOfSegment(segmentName)

end


function SpranimationTrack:Play(speed)

    self._playing = coroutine.wrap(function()

        while true do
            local spranimation = self.Spranimation

            for i, segment in pairs(spranimation._segmentTable) do
                local framesInSegment = segment.EndFrame - segment.StartFrame + 1

                for frame = segment.StartFrame, segment.EndFrame do
                    self._spranimator:SetFrame(frame)
                    FastWait(segment.Length/framesInSegment)
                end
            end
        end

    end)

    self._playing()
end


function SpranimationTrack:Stop()

end


return SpranimationTrack