--[[
    Pipe Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Pipe class represents the pipes that randomly spawn in our game, which act as our primary obstacles.
    The pipes can stick out a random distance from the top or bottom of the screen. When the player collides
    with one of them, it's game over. Rather than our bird actually moving through the screen horizontally,
    the pipes themselves scroll through the game to give the illusion of player movement.
]]

Pipe = Class{}

-- since we only want the image loaded once, not per instantation, define it externally
local PIPE_IMAGE = love.graphics.newImage('textures/pipe.png')
PIPE_WIDTH = PIPE_IMAGE:getWidth()
PIPE_HEIGHT = PIPE_IMAGE:getHeight()

function Pipe:init(orientation, y)
    self.bound = Rect(
        VIRTUAL_WIDTH,     -- initialize pipes past the right edge of the screen
        y, 
        PIPE_WIDTH, 
        PIPE_HEIGHT
    )

    self.orientation = orientation

    self.dx = -FOREGROUND_SCROLL_SPEED   -- velocity in x direction
    
    -- whether this pipe is ready to be removed from the scene
    self.remove = false
end

function Pipe:update(dt)
    -- remove the pipe from the scene if it's beyond the left edge of the screen,
    -- else move it from right to left
    if self.bound.x > -self.bound.width then
        self.bound.x = self.bound.x + self.dx * dt
    else
        self.remove = true
    end
end

function Pipe:render()
    -- last argument: y scale. if applying a negative y scale, the sprite will be mirrored on its y value
    -- when mirroring the upper pipe the y position to draw will be its lower edge. Thats why it needs to be shifted down by its height when drawing.
    love.graphics.draw(PIPE_IMAGE, self.bound.x, self.orientation == 'top' and self.bound.y + self.bound.height or self.bound.y, 
        0,  -- rotation
        1,  -- x scale
        self.orientation == 'top' and -1 or 1
    )
end
