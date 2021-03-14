local Spranimator = {}

Spranimator.__index = Spranimator


function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self.Adornee = gui
    self.ClassName = "Spranimator"
    self.Name = "Spranimator"

    self.Changed = Instance.new("BindableEvent")
    self.AnimationPlayed = Instance.new("BindableEvent")

    return self

end


function Spranimator:GetPlayingSpranimationTracks()

end


function Spranimator:LoadSpranimation(Spranimation)
    return SpranimationTrack.new(Spranimation)
end


function Spranimator:StepSpranimations(dt)

end


return Spranimator