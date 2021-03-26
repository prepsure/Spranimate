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


function Spranimator:SetFrame(frame)
    local zeroIndexed = frame - 1

    local spritesPerRow = self.ImageSize.X/self.SpriteSize.X

    local col = zeroIndexed % spritesPerRow
    local row = math.floor(zeroIndexed / spritesPerRow)

    self.Adornee.ImageRectOffset = Vector2.new(col * self.SpriteSize.X, row * self.SpriteSize.Y)
end


function Spranimator:GetPlayingSpranimationTracks()

end


function Spranimator:LoadSpranimation(Spranimation)
    local track = SpranimationTrack.new(Spranimation, self)

    table.insert(self._tracks, track)
    return track
end


function Spranimator:StepSpranimations(dt)

end


return Spranimator