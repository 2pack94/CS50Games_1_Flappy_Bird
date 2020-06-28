--[[
    GD50 2018
    Flappy Bird Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A mobile game by Dong Nguyen that went viral in 2013, utilizing a very simple 
    but effective gameplay mechanic of avoiding pipes indefinitely by just tapping 
    the screen, making the player's bird avatar flap its wings and move upwards slightly. 
    A variant of popular games like "Helicopter Game" that floated around the internet
    for years prior. Illustrates some of the most basic procedural generation of game
    levels possible as by having pipes stick out of the ground by varying amounts, acting
    as an infinitely generated obstacle course for the player.
]]

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'lib/push'

-- the "Class" library we're using will allow us to represent anything in
-- our game as code, rather than keeping track of many disparate variables and
-- methods
--
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'lib/class'

require 'lib/Rect'

-- a basic StateMachine class which will allow us to transition to and from
-- game states smoothly and avoid monolithic code in one file
require 'lib/StateMachine'

require 'states/BaseState'
require 'states/CountdownState'
require 'states/PlayState'
require 'states/PauseState'
require 'states/ScoreState'
require 'states/TitleScreenState'

require 'Bird'
require 'Pipe'
require 'PipePair'

-- physical screen dimensions
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution dimensions
VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

-- picture for the background (has the same height as VIRTUAL_HEIGHT)
local background = love.graphics.newImage('textures/background.png')
local background_scroll = 0      -- number of pixels on the negative x-axis that the background has traveled

local ground = love.graphics.newImage('textures/ground.png')
local ground_scroll = 0      -- number of pixels on the negative x-axis that the ground has traveled
GROUND_HEIGHT = ground:getHeight()

-- create a Parallax effect with different scrolling speed for background and foreground
FOREGROUND_SCROLL_SPEED = 90
BACKGROUND_SCROLL_SPEED = FOREGROUND_SCROLL_SPEED / 2

-- when this background_scroll is reached, reset the background_scroll to 0 (picture gets shifted to the starting point)
-- background.png is drawn in a way that it repeats periodic with BACKGROUND_LOOPING_POINT. Its width is more than BACKGROUND_LOOPING_POINT + VIRTUAL_WIDTH
local BACKGROUND_LOOPING_POINT = 413

-- global variable we can use to scroll the map
scrolling = true

-- Runs when the game first starts up, only once; used to initialize the game.
function love.load()
    -- initialize our nearest-neighbor filter
    love.graphics.setDefaultFilter('nearest', 'nearest')
    
    -- seed the RNG
    math.randomseed(os.time())

    -- app window title
    love.window.setTitle('Flappy Bird')

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('fonts/font.ttf', 8)
    mediumFont = love.graphics.newFont('fonts/flappy.ttf', 14)
    flappyFont = love.graphics.newFont('fonts/flappy.ttf', 28)
    hugeFont = love.graphics.newFont('fonts/flappy.ttf', 56)

    -- initialize our table of sounds
    -- type "static" means that the audio file is loaded in memory at initialization time
    sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['explosion'] = love.audio.newSource('sounds/explosion.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),

        -- https://freesound.org/people/xsgianni/sounds/388079/
        ['music'] = love.audio.newSource('sounds/marios_way.mp3', 'static')
    }

    -- kick off music
    sounds['music']:setLooping(true)
    sounds['music']:setVolume(0.8)
    sounds['music']:play()

    -- initialize our virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize state machine with all state class returning functions
    gStateMachine = StateMachine({
        ['title'] = function() return TitleScreenState() end,
        ['countdown'] = function() return CountdownState() end,
        ['play'] = function() return PlayState() end,
        ['pause'] = function() return PauseState() end,
        ['score'] = function() return ScoreState() end
    })
    -- change() instantiates a State class (calls: exit() of previous state class -> init() of the new state class -> enter() of the new state class)
    -- objects or variables needed in more than 1 state can be tranferred with the second Parameter 'enterParams' of the change() method. They will be available in the enter() method of the next state
    -- if not referenced by something else (e.g. by passing them as 'enterParams' for the next state),
    -- the previous state object and all of its members get discarded and cleaned up (Lua garbage collection) (because the variable the state object was assigned to gets overwritten by the next state object)
    gStateMachine:change('title')

    -- initialize input table
    keys_pressed = {}
    -- initialize mouse input table
    buttons_pressed = {}
end

-- Called by LÖVE whenever we resize the screen
function love.resize(w, h)
    push:resize(w, h)
end

-- called by LÖVE2D when a key is pressed
function love.keypressed(key)
    -- add to the table of keys pressed
    keys_pressed[key] = true

    if key == 'escape' then
        love.event.quit()
    end
end

-- LÖVE2D callback fired each time a mouse button is pressed; gives us the X and Y of the mouse, as well as the button in question.
function love.mousepressed(x, y, button)
    buttons_pressed[button] = true
end

-- this function can be called in all states and in all objects in order to get the keys pressed
function keyboardWasPressed(key)
    return keys_pressed[key]
end

-- Equivalent to keyboardWasPressed(), but for mouse buttons.
function mouseWasPressed(button)
    return buttons_pressed[button]
end

-- Called every frame by LÖVE. dt is the delta in seconds since the last frame
function love.update(dt)
    -- if the games freezes (e.g. when the window gets moved), dt gets accumulated and will be applied in the next update.
    -- prevent the glitches caused by that by limiting dt to 0.07 (about 1/15) seconds.
    dt = math.min(dt, 0.07)

    if scrolling then
        background_scroll = (background_scroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
        ground_scroll = (ground_scroll + FOREGROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH
    end

    -- update the currently active state
    gStateMachine:update(dt)

    -- clear the keys pressed table every frame after the keys were processed by the active state
    keys_pressed = {}
    buttons_pressed = {}
end

-- Called after update by LÖVE2D, used to draw anything to the screen
function love.draw()
    push:start()
    
    love.graphics.draw(background, -background_scroll, 0)
    gStateMachine:render()
    love.graphics.draw(ground, -ground_scroll, VIRTUAL_HEIGHT - GROUND_HEIGHT)   -- draw ground on top of pipes
    
    push:finish()
end
