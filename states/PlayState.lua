--[[
    PlayState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The PlayState class is the bulk of the game, where the player actually controls the bird and
    avoids pipes. When the player collides with a pipe, we should go to the GameOver state, where
    we then go back to the main menu.
]]

-- inherits from BaseState
PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.score = 0
    self.bird = Bird()
    self.pipe_pairs = {}             -- table of pipe pairs that are loaded
    self.pipe_spawn_timer = 0
    self.pipe_spawn_timer_elapsed = true
    -- pipe spawn time in milliseconds. rate at which a new pipe pair spawns. (must be integer)
    self.pipe_max_spawn_time = 1500
    self.pipe_min_spawn_time = 3000
    self.pipe_spawn_time = math.random(self.pipe_min_spawn_time, self.pipe_max_spawn_time)

    self.pipe_margin_y = 20     -- minimum amount of pixels the top pipe is inside the screen
    -- initialize our last recorded y value for a gap placement to base other gaps off of
    self.pipepair_last_y = -PIPE_HEIGHT + math.random(80) + self.pipe_margin_y
    self.pipepair_gap_height = 0        -- gap between the pipes
    self.pipepair_min_gap_height = 85
    self.pipepair_max_gap_height = 150
    self.pipepair_max_change_y = 50     -- maximum change in y position from one pipe pair to the next
end

function PlayState:update(dt)
    -- update timer for pipe spawning
    self.pipe_spawn_timer = self.pipe_spawn_timer + dt * 1000
    if self.pipe_spawn_timer > self.pipe_spawn_time then
        self.pipe_spawn_timer_elapsed = true
    end

    -- spawn a new pipe pair every second and a half
    if self.pipe_spawn_timer_elapsed then
        -- reset timer
        self.pipe_spawn_timer = 0
        self.pipe_spawn_timer_elapsed = false

        -- recalculate the gap of the current pipes and when the next pipes should spawn
        self.pipe_spawn_time = math.random(self.pipe_min_spawn_time, self.pipe_max_spawn_time)
        self.pipepair_gap_height = math.random(self.pipepair_min_gap_height, self.pipepair_max_gap_height)

        -- if pipepair_y = -PIPE_HEIGHT then the lower edge of the top pipe is excactly at the top edge of the screen
        local pipepair_y = math.max(
            -PIPE_HEIGHT + self.pipe_margin_y,                                                                  -- smallest y (highest position)
            math.min(
                self.pipepair_last_y + math.random(-self.pipepair_max_change_y, self.pipepair_max_change_y),    -- change y from its last value
                VIRTUAL_HEIGHT - PIPE_HEIGHT - self.pipepair_gap_height - GROUND_HEIGHT                         -- biggest y (lowest position)
            )
        )

        self.pipepair_last_y = pipepair_y

        -- add a new pipe pair at the end of the screen at our new pipepair_y
        table.insert(self.pipe_pairs, PipePair(pipepair_y, self.pipepair_gap_height))
    end

    -- for every pair of pipes
    for k, pair in pairs(self.pipe_pairs) do
        -- score a point if the pipe has gone past the bird to the left all the way
        -- be sure to ignore it if it's already been scored
        if not pair.scored then
            if pair.x + PIPE_WIDTH < self.bird.bound.x then
                self.score = self.score + 1
                pair.scored = true
                sounds['score']:play()
            end
        end
        -- update position of pair
        pair:update(dt)
    end
    -- we need this second loop, rather than deleting in the previous loop, because
    -- modifying the table in-place without explicit keys will result in skipping the
    -- next pipe, since all implicit keys (numerical indices) are automatically shifted
    -- down after a table removal
    for k, pair in pairs(self.pipe_pairs) do
        if pair.remove then
            table.remove(self.pipe_pairs, k)
        end
    end

    -- update bird based on gravity and input
    self.bird:update(dt)

    -- simple collision between bird and all pipes in pairs. change to score state if collided with a pipe
    local bird_collided = false
    for k, pair in pairs(self.pipe_pairs) do
        for l, pipe in pairs(pair.pipes) do
            if self.bird:collides(pipe.bound) then
                bird_collided = true
            end
        end
    end
    -- reset if we get to the ground or fly too high
    if self.bird.hitbox.y + self.bird.hitbox.height > VIRTUAL_HEIGHT - GROUND_HEIGHT or self.bird.hitbox.y < 0 then
        bird_collided = true
    end
    if bird_collided then
        sounds['explosion']:play()
        sounds['hurt']:play()
        -- supply the ScoreState with the score, bird and pipes as a Parameter in the enter() function
        gStateMachine:change('score', {score = self.score, bird = self.bird, pipes = self.pipe_pairs})
    end

    if keyboardWasPressed(PAUSE_KEY) then
        -- supply the Playstate object (self) to the PauseState to be able to resume this Playstate from where it was left off.
        -- classes in Lua are a table (Lua equivalent to dictionary in Python)
        gStateMachine:change('pause', {playstate = self})
    end
end

function PlayState:render()
    for k, pair in pairs(self.pipe_pairs) do
        pair:render()
    end

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)

    self.bird:render()
end

--[[
    Called when this state is transitioned to from another state.
]]
function PlayState:enter(params)
    -- if we're coming from death or Pause, restart scrolling
    scrolling = true
    -- in case PlayState was entered from the PauseState, reset the states of gStateMachine that were altered in the PauseState
    gStateMachine.states['play'] = function() return PlayState() end
end

--[[
    Called when this state changes to another state.
]]
function PlayState:exit()
    -- stop scrolling for the score/ pause screen
    scrolling = false
end
