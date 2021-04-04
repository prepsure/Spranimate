local RunService = game:GetService("RunService")

local modules = script.Parent.Modules
local Janitor = require(modules.Janitor)
local Signal = require(modules.Signal)

local SpranimationTrack = require(script.Parent.SpranimationTrack)


local Spranimator = {}

Spranimator.__index = Spranimator
Spranimator.ClassName = "Spranimator"


function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self._janitor = Janitor.new()

    -- public
    self.Adornee = gui
    self.Name = "Spranimator"

    self.SpriteSize = gui:GetAttribute("SpriteSize")
    self.ImageSize = gui:GetAttribute("ImageSize")
    self.SpranimationPlayed = self._janitor:Add( Signal.new() )

    -- private
    self._tracks = {}
    self:_runSpranimations()

    return self

end


function Spranimator:_runSpranimations()
    local onTop = self._tracks[1]

    self._janitor:Add(
        RunService.Heartbeat:Connect(function(dt)
            local lastOnTop = onTop

            for i, track in pairs(self._tracks) do
                if not track.IsPlaying then
                    continue
                end

                track:Seek((track.TimePosition + dt) % track.Length)

                onTop = (track.Priority.Value > onTop.Priority.Value) and track or onTop
            end

            self:SetFrame(onTop.CurrentFrame, onTop.FlipX, onTop.FlipY)

            if onTop ~= lastOnTop then
                self.SpranimationSwitched:Fire()
            end
        end)
    )
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
    local track = SpranimationTrack.new(Spranimation)
    self._janitor:Add(track)

    table.insert(self._tracks, track)
    return track
end


function Spranimator:StepSpranimations(frames)
    for _, t in pairs(self._tracks) do
        t:AdvanceFrame(frames)
    end
end


function Spranimator:Clone()
    return Spranimator.new(self.Adornee)
end


function Spranimator:Destroy()
    self._janitor:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end


return Spranimator