--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

-- inherits from BaseState
ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
    Also continue to render the bird and the pipes, but don't update them any more.
]]
function ScoreState:enter(params)
    self.score = params.score
    self.bird = params.bird
    self.pipes = params.pipes
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if keyboardWasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- render bird and pipe objects from the PlayState
    for k, pair in pairs(self.pipes) do
        pair:render()
    end
    self.bird:render()

    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.printf('Press Enter to Play Again!', 0, 160, VIRTUAL_WIDTH, 'center')
end
