local RunService = game:GetService("RunService")

local modules = script.Parent.Modules
local Janitor = require(modules.Janitor)
local Signal = require(modules.Signal)

local SpranimationTrack = require(script.Parent.SpranimationTrack)


local Spranimator = {}

Spranimator.__index = Spranimator
Spranimator.ClassName = "Spranimator"


---------- constructor ----------


--- constructs a new Spranimator

function Spranimator.new(gui)

    local self = setmetatable({}, Spranimator)

    self._janitor = Janitor.new()

    -- public
    self.Adornee = gui
    self.Name = self.ClassName

    self.SpriteSize = gui:GetAttribute("SpriteSize")
    self.SheetSize = gui:GetAttribute("SheetSize")

    self.SpranimationSwitched = self._janitor:Add( Signal.new() )

    -- private
    self._tracks = {}
    self:_runSpranimations()

    return self

end


---------- private functions ----------


function Spranimator:_runSpranimations()
    local onTop = nil

    self._janitor:Add(
        RunService.Heartbeat:Connect(function(dt)
            local lastOnTop = onTop
            onTop = nil

            -- tracks to remove from the queue
            local toRemove = {}

            for i, track in pairs(self._tracks) do

                -- if track is destroyed, add it to the list and do nothing
                if track._destroyed then
                    table.insert(toRemove, i)
                    continue
                end

                if not track.IsPlaying then
                    continue
                end

                track:Seek((track.TimePosition + dt) % track.Length)

                if (not onTop) or (track.Priority.Value > onTop.Priority.Value) then
                    onTop = track
                end
            end

            -- remove tracks that are destroyed
            for j = #toRemove, 1, -1 do
                table.remove(self._tracks, toRemove[j])
            end

            -- set the frame with the highest priority on top
            if onTop then
                self:SetFrame(onTop.CurrentFrame, onTop.FlipX, onTop.FlipY)
            end

            -- fire SpranimationSwitched if needed
            if onTop ~= lastOnTop then
                self.SpranimationSwitched:Fire(onTop)
            end

        end)
    )
end


---------- public functions ----------


--- sets the frame for the spritesheet which the Spranimator is playing on
-- @param frame <integer> - the frame number starting from the upper left and continuing to the right and then down
--                        - must be in the range [1, spriteCount]
-- @param flipX <bool>    - whether or not to flip the frame horizontally
-- @param flipY <bool>    - whether or not to flip the frame vertically

function Spranimator:SetFrame(frame, flipX, flipY)
    local zeroIndexed = frame - 1

    local spritesPerRow = self.SheetSize.X/self.SpriteSize.X

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


--- gets all playing spranimationTracks (including ones that aren't setting the frame)

function Spranimator:GetPlayingSpranimationTracks()
    local playingTracks = {}

    for _, t in pairs(self._tracks) do
        if t.IsPlaying then
            table.insert(playingTracks, t)
        end
    end

    return playingTracks
end


--- loads a Spranimation into the Spranimator's queue
-- @param  spranimation <Spranimation>      - the Spranimation to load
-- @return track        <SpranimationTrack> - a SpranimationTrack based on the given Spranimation

function Spranimator:LoadSpranimation(spranimation)
    local track = SpranimationTrack.new(spranimation)
    self._janitor:Add(track)

    table.insert(self._tracks, track)
    return track
end


--- steps each loaded Spranimation a certain number of frames
-- @param frames <integer> - the number of frames to step

function Spranimator:StepSpranimations(frames)
    for _, t in pairs(self._tracks) do
        t:AdvanceFrame(frames)
    end
end


----------- roblox instance functions ----------


--- copies the Spranimator, but not the loaded SpranimationTracks
-- @return clone <Spranimator> - the copied Spranimator

function Spranimator:Clone()
    return Spranimator.new(self.Adornee)
end


--- destroys the Spranimator, rendering it unusable

function Spranimator:Destroy()
    self._janitor:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end


return Spranimator