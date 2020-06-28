--[[
    Bird Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Bird is what we control in the game via clicking or the space bar; whenever we press either,
    the bird will flap and go up a little bit, where it will then be affected by gravity. If the bird hits
    the ground or a pipe, the game is over.
]]

Bird = Class{}

local GRAVITY = 1000        -- in pixel per second per second

function Bird:init()
    self.image = love.graphics.newImage('textures/bird.png')
    -- initialize the boundary of the bird in the middle of the screen
    -- x, y, width, height
    self.bound = Rect(
        VIRTUAL_WIDTH / 2 - self.image:getWidth() / 2, 
        VIRTUAL_HEIGHT / 2 - self.image:getHeight() / 2, 
        self.image:getWidth(), 
        self.image:getHeight()
    )
    self.hitbox_margin = 2   -- in pixels. spacing between hitbox and boundary on all sides. a smaller hitbox gives a more pleasant experience.
    self.hitbox = Rect(
        self.bound.x + self.hitbox_margin,
        self.bound.y + self.hitbox_margin,
        self.bound.width - self.hitbox_margin * 2,
        self.bound.height - self.hitbox_margin * 2
    )
    self.dy = 0             -- y velocity
    self.max_dy = 1000      -- maximum y velocity
    self.jump_dy = -300     -- jump speed (jump goes in negative y direction)
end

function Bird:collides(pipe_bound)
    return self.hitbox:intersects(pipe_bound)
end

--[[
    The position of *self is updated with the Semi-implicit Euler Integration. It uses the the new velocity to update d.
    v: velocity, v_0: velocity of the previous frame, a: acceleration, d: position, d_0: position of the previous frame
    1. calculate the velocity with explicit Euler: v = a * t + v_0
    2. calculate the position with implicit Euler: d = v * t + d_0 = a * t^2 + v_0 * t + d_0
    The solution of Explicit Euler would be: d = (a / 2) * t^2 + v_0 * t + d_0
    -> only correct when acceleration is constant. Uses the average velocity between v and v_0 to update d
]]
function Bird:update(dt)
    if keyboardWasPressed('space') or mouseWasPressed(1) then
        self.dy = self.jump_dy
        sounds['jump']:play()
    else
        self.dy = self.dy + GRAVITY * dt
        self.dy = math.min(self.dy, self.max_dy)
    end
    self.bound.y = self.bound.y + self.dy * dt
    self.hitbox.y = self.bound.y + self.hitbox_margin
end

function Bird:render()
    love.graphics.draw(self.image, self.bound.x, self.bound.y)
end
