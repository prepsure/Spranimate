local RunService = game:GetService("RunService")
local SpranimationTrack = require(script.Parent.SpranimationTrack)


local Spranimator = {}

Spranimator.__index = Spranimator
Spranimator.ClassName = "Spranimator"


function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self.Adornee = gui
    self.Name = "Spranimator"

    self.SpriteSize = gui:GetAttribute("SpriteSize")
    self.ImageSize = gui:GetAttribute("ImageSize")

    self.Changed = Instance.new("BindableEvent")
    self.AnimationPlayed = Instance.new("BindableEvent")

    self._tracks = {}

    self._setFrameCxn = RunService.Heartbeat:Connect(function()
        self:_setHighestPriorityPlayingFrame()
    end)

    return self

end


function Spranimator:_setHighestPriorityPlayingFrame()
    if #self._tracks == 0 then
        return
    end

    local highest = self._tracks[1]

    for i, track in pairs(self._tracks) do
        if track.IsPlaying and (track.Priority.Value > highest.Priority.Value) then
            highest = track
        end
    end

    self:SetFrame(highest.CurrentFrame, highest.FlipX, highest.FlipY)
end


function Spranimator:SetFrame(frame, flipX, flipY)
    local zeroIndexed = frame - 1

    local spritesPerRow = self.ImageSize.X/self.SpriteSize.X

    local col = zeroIndexed % spritesPerRow
    local row = math.floor(zeroIndexed / spritesPerRow)
    local flipSize = self.SpriteSize

    if flipX then
        flipSize = Vector2.new(-flipSize.X, flipSize.Y)
        col += 1
    end

    if flipY then
        flipSize = Vector2.new(flipSize.X, -flipSize.Y)
        row += 1
    end

    self.Adornee.ImageRectOffset = Vector2.new(col * self.SpriteSize.X, row * self.SpriteSize.Y)
    self.Adornee.ImageRectSize = flipSize
end


function Spranimator:GetPlayingSpranimationTracks()
    local playingTracks = {}

    for _, t in pairs(self._tracks) do
        if t.IsPlaying then
            table.insert(playingTracks, t)
        end
    end

    return playingTracks
end


function Spranimator:LoadSpranimation(Spranimation)
    local track = SpranimationTrack.new(Spranimation, self)

    table.insert(self._tracks, track)
    return track
end


function Spranimator:StepSpranimations(frames)
    for _, t in pairs(self._tracks) do
        t:AdvanceFrame(frames)
    end
end


return Spranimator