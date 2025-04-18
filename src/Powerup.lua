Powerup = Class{}

function Powerup:init()
    -- x is placed in the middle
    self.x = VIRTUAL_WIDTH / 2 - 8

    -- y is placed above the screen
    self.y = -16

    -- start us off with no velocity
    self.dy = 0

    self.width = 16
    self.height = 16

    self.type = 8

    self.falling = false
end

function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function Powerup:reset()
    self.x = VIRTUAL_WIDTH / 2 - 8
    self.y = -16
    self.dy = 0
    self.falling = false
    self.type = 8
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt

    if self.falling == true then
        self.dy = 20
    end
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
        self.x, self.y)
end