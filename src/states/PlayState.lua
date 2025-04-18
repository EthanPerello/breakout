--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.powerup = params.powerup
    
    self.powerupscore = 0
    self.paddlescore = 0

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    self.threeball = false
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)
    self.powerup:update(dt)

    -- every 2500 points scored causes the paddle size to increase
    if self.paddlescore >= 2500 then
        if self.paddle.size < 4 then
            self.paddle.size = self.paddle.size + 1
            self.paddle.width = self.paddle.width + 32
        end
        self.paddlescore = 0
    end

    -- every 1000 points scored causes a powerup to fall
    if self.powerupscore >= 1000 then
        self.powerup.falling = true
        self.powerupscore = 0
    end



    -- if powerup collides with the paddle it is activated
    if self.powerup:collides(self.paddle) then
        -- reset powerup

        gSounds['powerup']:play()

        if self.powerup.type == 9 then
            for k, brick in pairs(self.bricks) do
                brick.locked = false
            end
        end

        if self.powerup.type == 8 then
            self.threeball = true
            
            --spawn 2nd ball
            self.ball2 = Ball()
            self.ball2.skin = math.random(7)
            self.ball2.x = VIRTUAL_WIDTH / 2 - 4
            self.ball2.y = VIRTUAL_HEIGHT / 2 - 4
            self.ball2.dx = math.random(-200, 200)
            self.ball2.dy = math.random(-50, -60)

            -- spawn 3rd ball
            self.ball3 = Ball()
            self.ball3.skin = math.random(7)
            self.ball3.x = VIRTUAL_WIDTH / 2 - 4
            self.ball3.y = VIRTUAL_HEIGHT / 2 - 4
            self.ball3.dx = math.random(-200, 200)
            self.ball3.dy = math.random(-50, -60)
        end

        self.powerup:reset()
    end

    if self.threeball == true then
        self.ball2:update(dt)
        self.ball3:update(dt)
    end

    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end


    if self.threeball == true then
        if self.ball2:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.ball2.y = self.paddle.y - 8
            self.ball2.dy = -self.ball2.dy

            -- tweak angle of bounce based on where it hits the paddle

            -- if we hit the paddle on its left side while moving left...
            if self.ball2.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball2.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball2.x))
        
            -- else if we hit the paddle on its right side while moving right...
            elseif self.ball2.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.ball2.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball2.x))
            end

            gSounds['paddle-hit']:play()
        end

        if self.ball3:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.ball3.y = self.paddle.y - 8
            self.ball3.dy = -self.ball3.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.ball3.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.ball3.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball3.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif self.ball3.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.ball3.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball3.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    for k, brick in pairs(self.bricks) do
        if brick.inPlay and brick.locked == true then
            self.powerup.type = 9
        end
    end
    
    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and (self.ball:collides(brick)) then

            -- add to score
            if brick.locked == false then
                if brick.keyposition == 0 then
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                    self.powerupscore = self.powerupscore + (brick.tier * 200 + brick.color * 25)
                    self.paddlescore = self.paddlescore + (brick.tier * 200 + brick.color * 25)
                else
                    self.score = self.score + 5000
                    self.powerupscore = self.score + 5000
                    self.paddlescore = self.score + 5000
                end
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints,
                    powerup = self.powerup
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners

            -- only check collision if we're in play

            break
        end

        if self.threeball == true then
            -- only check collision if we're in play
            if brick.inPlay and (self.ball2:collides(brick)) then

                -- add to score
                if brick.locked == false then
                    if brick.keyposition == 0 then
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)
                        self.powerupscore = self.powerupscore + (brick.tier * 200 + brick.color * 25)
                        self.paddlescore = self.paddlescore + (brick.tier * 200 + brick.color * 25)
                    else
                        self.score = self.score + 5000
                        self.powerupscore = self.score + 5000
                        self.paddlescore = self.score + 5000
                    end
                end

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints,
                        powerup = self.powerup
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.ball2.x + 2 < brick.x and self.ball2.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.ball2.dx = -self.ball2.dx
                    self.ball2.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.ball2.x + 6 > brick.x + brick.width and self.ball2.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.ball2.dx = -self.ball2.dx
                    self.ball2.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif self.ball2.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    self.ball2.dy = -self.ball2.dy
                    self.ball2.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    self.ball2.dy = -self.ball2.dy
                    self.ball2.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.ball2.dy) < 150 then
                    self.ball2.dy = self.ball2.dy * 1.02
                end

                -- only allow colliding with one brick, for corners

                -- only check collision if we're in play

                break
            end
        end

        if self.threeball == true then
            -- only check collision if we're in play
            if brick.inPlay and (self.ball3:collides(brick)) then

                -- add to score
                if brick.locked == false then
                    if brick.keyposition == 0 then
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)
                        self.powerupscore = self.powerupscore + (brick.tier * 200 + brick.color * 25)
                        self.paddlescore = self.paddlescore + (brick.tier * 200 + brick.color * 25)
                    else
                        self.score = self.score + 5000
                        self.powerupscore = self.score + 5000
                        self.paddlescore = self.score + 5000
                    end
                end

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = self.ball,
                        recoverPoints = self.recoverPoints,
                        powerup = self.powerup
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if self.ball3.x + 2 < brick.x and self.ball3.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.ball3.dx = -self.ball3.dx
                    self.ball3.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.ball3.x + 6 > brick.x + brick.width and self.ball3.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.ball3.dx = -self.ball3.dx
                    self.ball3.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif self.ball3.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    self.ball3.dy = -self.ball3.dy
                    self.ball3.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    self.ball3.dy = -self.ball3.dy
                    self.ball3.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.ball3.dy) < 150 then
                    self.ball3.dy = self.ball3.dy * 1.02
                end

                -- only allow colliding with one brick, for corners

                -- only check collision if we're in play

                break
            end
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        -- decrease paddle size
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
            self.paddle.width = self.paddle.width - 32
        end

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                powerup = self.powerup
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()
    self.powerup:render()

    if self.threeball==true then
        self.ball2:render()
        self.ball3:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end