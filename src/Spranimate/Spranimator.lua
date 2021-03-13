local Spranimator = {}

Spranimator.__index = Spranimator


function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self.Gui = gui or Instance.new("ImageLabel")
    self.ClassName = "Spranimator"
    self.Name = "Spranimator"

    self.Changed = Instance.new("BindableEvent")
    self.AnimationPlayed = Instance.new("BindableEvent")

    return self

end


function Spranimator:GetPlayingAnimationTracks()

end


function Spranimator:LoadAnimation(SpranimationTrack)

end


function Spranimator:StepAnimations(dt)

end


return Spranimator