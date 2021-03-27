local RunService = game:GetService("RunService")
local SpranimationTrack = require(script.Parent.SpranimationTrack)


local Spranimator = {}

Spranimator.__index = Spranimator


function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self.Adornee = gui
    self.ClassName = "Spranimator"
    self.Name = "Spranimator"

    self.SpriteSize = gui:GetAttribute("SpriteSize")
    self.ImageSize = gui:GetAttribute("ImageSize")

    self.Changed = Instance.new("BindableEvent")
    self.AnimationPlayed = Instance.new("BindableEvent")

    self._tracks = {}

    return self

end


function Spranimator:_isHighestPriorityPlayingTrack(track)
    for i, t in pairs(self._tracks) do
        if not t.IsPlaying then
            continue
        end

        if t.Priority.Value >= track.Priority.Value then
            return t == track
        end
    end

    return true
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