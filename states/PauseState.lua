--[[
    PauseState Class
    Author: Richard Tuppack

    The PauseState can be accessed from the PlayState by pressing the Pause key.
    When pressing the Pause key again, transition back to the PlayState and continue the game from where it was left off.
]]

-- inherits from BaseState
PauseState = Class{__includes = BaseState}

PAUSE_KEY = 'p'

function PauseState:update(dt)
    -- go back to play if the pause key is pressed
    if keyboardWasPressed(PAUSE_KEY) then
        gStateMachine:change('play')
    end
end

function PauseState:render()
    -- render everything that was present in the PlayState. Just don't update anything
    self.playstate:render()
    -- display 'Pause'
    love.graphics.setFont(hugeFont)
    love.graphics.printf('Pause', 0, 100, VIRTUAL_WIDTH, 'center')
end

function PauseState:enter(params)
    sounds['music']:pause()     -- pause the music
    -- store the current Playstate object to be able to resume this Playstate from where it was left off.
    self.playstate = params.playstate       -- shallow copy
    -- change the play state of gStateMachine.
    -- return the stored Playstate instead of instantiating a new PlayState object on the next State change (like it was defined in main).
    -- change it back afterwards.
    gStateMachine.states['play'] = function() return self.playstate end
end

function PauseState:exit()
    sounds['music']:play()      -- resume the music before returning to play
end
