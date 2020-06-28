--[[
    PipePair Class

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Used to represent a pair of pipes that stick together as they scroll, providing an opening
    for the player to jump through in order to score a point.
]]

PipePair = Class{}

function PipePair:init(y, gap_height)
    -- flag to hold whether this pair has been scored (jumped through)
    self.scored = false

    -- y value is for the upper edge of the topmost pipe; gap is a vertical shift of the second lower pipe
    self.y = y

    -- size of the gap between pipes in pixel
    self.gap_height = gap_height

    -- instantiate two pipes that belong to this pair
    self.pipes = {
        ['upper'] = Pipe('top', self.y),
        ['lower'] = Pipe('bottom', self.y + PIPE_HEIGHT + self.gap_height)
    }

    -- this should follow the x of a pipe member
    self.x = self.pipes['upper'].bound.x
end

function PipePair:update(dt)
    -- pairs() allows iteration over key-value pairs
    for key, pipe in pairs(self.pipes) do
        pipe:update(dt)
    end
    self.x = self.pipes['upper'].bound.x
end

function PipePair:render()
    for key, pipe in pairs(self.pipes) do
        pipe:render()
    end
end
