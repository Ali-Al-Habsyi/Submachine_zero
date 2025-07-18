--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Room = Class{}

function Room:init(player)
    self.width = MAP_WIDTH
    self.height = MAP_HEIGHT
    self.camX = 0
    self.camY = 0

    self.tiles = {}
    self:generateWallsAndFloors()
    self.cosmos_tiles = {}

    -- entities in the room
    self.entities = {}
    self:generateEntities()

    -- game objects in the room
    self.objects = {}
    self:generateObjects()

    -- doorways that lead to other dungeon rooms
    -- Disable for singular Map
    self.doorways = {}
    --table.insert(self.doorways, Doorway('top', false, self))
    --table.insert(self.doorways, Doorway('bottom', false, self))
    --table.insert(self.doorways, Doorway('left', false, self))
    --table.insert(self.doorways, Doorway('right', false, self))

    -- reference to player for collisions, etc.
    self.player = player

    -- used for centering the dungeon rendering
    self.renderOffsetX = MAP_RENDER_OFFSET_X
    self.renderOffsetY = MAP_RENDER_OFFSET_Y

    -- used for drawing when this room is the next room, adjacent to the active
    self.adjacentOffsetX = 0
    self.adjacentOffsetY = 0

    self.projectiles = {}

end

--[[ 
    Randomly creates an assortment of enemies for the player to fight.
]]
function Room:generateEntities()
    local types = {'skeleton', 'slime', 'bat', 'ghost', 'spider'}

    for i = 1, 10 do
        local type = types[math.random(#types)]

        --table.insert(self.entities, Entity {
        --    animations = ENTITY_DEFS[type].animations,
        --    walkSpeed = ENTITY_DEFS[type].walkSpeed or 20,

            -- ensure X and Y are within bounds of the map
        --    x = math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
        --        VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        --    y = math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
        --        VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16),
            
        --    width = 16,
        --    height = 16,

        --    health = 1
        --})

        --self.entities[i].stateMachine = StateMachine {
        --    ['walk'] = function() return EntityWalkState(self.entities[i]) end,
        --    ['idle'] = function() return EntityIdleState(self.entities[i]) end
        --}

        --self.entities[i]:changeState('walk')
    end
end

--[[
    Randomly creates an assortment of obstacles for the player to navigate around.
]]
function Room:generateObjects()
    local switch = GameObject(
        GAME_OBJECT_DEFS['switch'],
        math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                    VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
        math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                    VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
    )

    -- define a function for the switch that will open all doors in the room
    switch.onCollide = function()
        if switch.state == 'unpressed' then
            switch.state = 'pressed'
            
            -- open every door in the room if we press the switch
            for k, doorway in pairs(self.doorways) do
                doorway.open = true
            end

            gSounds['door']:play()
        end
    end

    -- add to list of objects in scene (only one switch for now)
    -- table.insert(self.objects, switch)

    for i=0, 10, 1 do
        local pot
        while true do
            pot = GameObject(
                GAME_OBJECT_DEFS['pot'],
                math.random(MAP_RENDER_OFFSET_X + TILE_SIZE,
                            VIRTUAL_WIDTH - TILE_SIZE * 2 - 16),
                math.random(MAP_RENDER_OFFSET_Y + TILE_SIZE,
                            VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) + MAP_RENDER_OFFSET_Y - TILE_SIZE - 16)
            )
            for k, obj in pairs(self.objects) do
                if (pot.x + pot.width < obj.x or pot.x > obj.x + obj.width or
                pot.y + pot.height < obj.y or pot.y > obj.y + obj.height) then
                    goto double_break
                end
            end
        end
        ::double_break::
        pot.onCollide = function()

        end
        --table.insert(self.objects, pot)
    end
end

--[[
    Generates the walls and floors of the room, randomizing the various varieties
    of said tiles for visual variety.
]]
function Room:generateWallsAndFloors()
    for y = 1, self.height do
        table.insert(self.tiles, {})

        for x = 1, self.width do
            local id = TILE_EMPTY

            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            
            table.insert(self.tiles[y], {
                id = id
            })
        end
    end
end

function Room:update(dt)
    
    -- don't update anything if we are sliding to another room (we have offsets)
    if self.adjacentOffsetX ~= 0 or self.adjacentOffsetY ~= 0 then return end

    self.player:update(dt)
    self:updateCamera()

    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]

        -- remove entity from the table if health is <= 0
        if entity.health <= 0 then
            -- Create hearth before setting entity as dead, to avoid multiple spawnings
            if not entity.dead then
                if math.random(10000) < 40 * 100 then
                    local hearth_object = GameObject(GAME_OBJECT_DEFS['heart'], entity.x, entity.y)
                    hearth_object.onCollide = function() 
                        if hearth_object.is_active and self.player.health < 6 then
                            self.player.health = math.min(self.player.health + 2, 6)
                            hearth_object.is_active = false
                        end
                    end
                    table.insert(self.objects, hearth_object)
                end
            end
            entity.dead = true
        elseif not entity.dead then
            entity:processAI({room = self}, dt)
            entity:update(dt)
        end

        -- collision between the player and entities in the room
        if not entity.dead and self.player:collides(entity) and not self.player.invulnerable then
            gSounds['hit-player']:play()
            self.player:damage(1)
            self.player:goInvulnerable(1.5)

            if self.player.health == 0 then
                gStateMachine:change('game-over')
            end
        end
    end

    for k, object in pairs(self.objects) do
        object:update(dt)

        -- trigger collision callback on object
        if self.player:collides(object) then
            object:onCollide()

            if object.solid and not object.taken then
                local playerCenter = self.player.y + self.player.height / 2
                local playerHeight = self.player.height - self.player.height / 2
                local playerMaxX = self.player.x + self.player.width
                local playerMaxY = playerCenter + playerHeight
                
                if self.player.direction == 'left' and not (playerCenter >= (object.y + object.height)) and not (playerMaxY <= object.y) then
                    self.player.x = object.x + object.width
                elseif self.player.direction == 'right' and not (playerCenter >= (object.y + object.height)) and not (playerMaxY <= object.y) then 
                    self.player.x = object.x - self.player.width
                elseif self.player.direction == 'down' and not (self.player.x >= (object.x + object.width)) and not (playerMaxX <= object.x) then
                    self.player.y = object.y - self.player.height
                elseif self.player.direction == 'up' and not (self.player.x >= (object.x + object.width)) and not (playerMaxX <= object.x) then
                    self.player.y = object.y + object.height - self.player.height/2
                end
            end

        end
    end

    for k, projectile in pairs(self.projectiles) do
        projectile:update(dt)

        -- check collision with entities
        for e, entity in pairs(self.entities) do
            if projectile.dead then
                break
            end

            if not entity.dead and projectile:collides(entity) then
                entity:damage(1)
                gSounds['hit-enemy']:play()
                projectile.dead = true
            end
        end

        if projectile.dead then
            table.remove(self.projectiles, k)
        end
    end
end

---- ROOM RENDERING IN DUNGEON RENDERING AND PLAYSTATE RENDERING.
--function Room:render()
--    love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][1],
--        1 + self.renderOffsetX + self.adjacentOffsetX, 
--        1 + self.renderOffsetY + self.adjacentOffsetY)

    -- adjust background X to move a third the rate of the camera for parallax
    -- translate the entire view of the scene to emulate a camera 
    -- self.level:render()
------------------------------------------------------------------------------------------------
    -- REQUIREMENT ENTIRE BACKGROUND, INCLUDING ROOM ENTITIES SHIFTING AS PLAYER SHIFTS
    -- CURRENT ACHIEVEMENT: SHIFTING BACKGORUND TEXTURE AS PLAYER SHIFTS
------------------------------------------------------------------------------------------------
    
    -- love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))

    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly

--    for k, doorway in pairs(self.doorways) do
        --doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
--    end

--    for k, object in pairs(self.objects) do
--        if not object.taken then
            --object:render(self.adjacentOffsetX, self.adjacentOffsetY)
--        end
--    end

--    for k, entity in pairs(self.entities) do
        --if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
--    end

    -- stencil out the door arches so it looks like the player is going through
--    love.graphics.stencil(function()
        
        -- left
--        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
--            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
--        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
--            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
--        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
--            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
--        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
--            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
--    end, 'replace', 1)

--    love.graphics.setStencilTest('less', 1)

--    if self.player then
--        self.player:render()
--    end
    --love.graphics.pop()

--    for k, projectile in pairs(self.projectiles) do
        -- projectile:render()
--    end

--    love.graphics.setStencilTest()

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)
    
    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    
    -- love.graphics.setColor(255, 255, 255, 255)
--end


------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- UPDATE TOWARDS LATEST VERSION
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

function Room:generateWallsAndFloors2()
    for y = 1, self.height do
        table.insert(self.tiles, {})
        for x = 1, self.width do
            local id = TILE_EMPTY
            if x == 1 and y == 1 then
                id = TILE_TOP_LEFT_CORNER
            elseif x == 1 and y == self.height then
                id = TILE_BOTTOM_LEFT_CORNER
            elseif x == self.width and y == 1 then
                id = TILE_TOP_RIGHT_CORNER
            elseif x == self.width and y == self.height then
                id = TILE_BOTTOM_RIGHT_CORNER
            -- random left-hand walls, right walls, top, bottom, and floors
            elseif x == 1 then
                id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
            elseif x == self.width then
                id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
            elseif y == 1 then
                id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
            elseif y == self.height then
                id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
            else
                id = TILE_FLOORS[math.random(#TILE_FLOORS)]
            end
            table.insert(self.cosmos_tiles[y], {
                id = id
            })
        end
    end
end














------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- UPDATE TOWARDS LATEST VERSION
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
---- ROOM RENDERING IN DUNGEON RENDERING AND PLAYSTATE RENDERING.
function Room:render()
    --love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][1],
    --    1 + self.renderOffsetX + self.adjacentOffsetX, 
    --    1 + self.renderOffsetY + self.adjacentOffsetY)

------******--------******---------******------******--------******---------******--------------
------******--------******---------******------******--------******---------******--------------
------******--------******---------******------******--------******---------******--------------
    
    --love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][1],
    --    1 + self.renderOffsetX + self.adjacentOffsetX, 
    --    1 + self.renderOffsetY + self.adjacentOffsetY)
    -- <><><> POINT OF DIFFICULTY

    --for k, doorway in pairs(self.doorways) do
    --    love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][1],
    --        1 + self.renderOffsetX + self.adjacentOffsetX, 
    --        1 + self.renderOffsetY + self.adjacentOffsetY)
    --end

    --for y = 1, self.height do
    --    for x = 1, self.width do
    --        local cosmos_tile = self.cosmos_tiles[y][x]
    --        love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][cosmos_tiles.id],
    --        (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX - 160, 
    --        (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY - 160)
    --    end
    --end

    trace = TraceMemory:generateTrace()
    trace_functional = {}

    for i in 1, #trace, do
        table.insert.append(trace_functional, trace[i][1])
    end

    for y = 1, self.height do
        for x = 1, self.width do
            local cosmos_tile = self.cosmos_tiles[y][x]
            if cosmos_tiles.id in trace_functional then
                love.graphics.draw(gTextures['black'], gFrames['black'][cosmos_tiles.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX - 160, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY - 160)
            else
                love.graphics.draw(gTextures['blue_cosmos'], gFrames['blue_cosmos'][cosmos_tiles.id],
                (x - 1) * TILE_SIZE + self.renderOffsetX + self.adjacentOffsetX - 160, 
                (y - 1) * TILE_SIZE + self.renderOffsetY + self.adjacentOffsetY - 160)
        end
    end

------******--------******---------******------******--------******---------******--------------
------******--------******---------******------******--------******---------******--------------
------******--------******---------******------******--------******---------******--------------

    -- adjust background X to move a third the rate of the camera for parallax
    -- translate the entire view of the scene to emulate a camera 
    --self.level:render()
------------------------------------------------------------------------------------------------
    -- REQUIREMENT ENTIRE BACKGROUND, INCLUDING ROOM ENTITIES SHIFTING AS PLAYER SHIFTS
    -- CURRENT ACHIEVEMENT: SHIFTING BACKGORUND TEXTURE AS PLAYER SHIFTS
------------------------------------------------------------------------------------------------
    
    --love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))
    -- render doorways; stencils are placed where the arches are after so the player can
    -- move through them convincingly

    for k, doorway in pairs(self.doorways) do
        --doorway:render(self.adjacentOffsetX, self.adjacentOffsetY)
    end

    for k, object in pairs(self.objects) do
        --if not object.taken then
            --object:render(self.adjacentOffsetX, self.adjacentOffsetY)
        end
    end

    for k, entity in pairs(self.entities) do
        --if not entity.dead then entity:render(self.adjacentOffsetX, self.adjacentOffsetY) end
    end

    -- stencil out the door arches so it looks like the player is going through
    love.graphics.stencil(function()
        
        -- left
        love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
            TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- right
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
            MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)
        
        -- top
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
        
        --bottom
        love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
            VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    end, 'replace', 1)

    love.graphics.setStencilTest('less', 1)

    if self.player then
        self.player:render()
    end
    --love.graphics.pop()

    for k, projectile in pairs(self.projectiles) do
        --projectile:render()
    end

    love.graphics.setStencilTest()

    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------

    --
    -- DEBUG DRAWING OF STENCIL RECTANGLES
    --

    -- love.graphics.setColor(255, 0, 0, 100)
    
    -- -- left
    -- love.graphics.rectangle('fill', -TILE_SIZE - 6, MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE,
    -- TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- right
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH * TILE_SIZE),
    --     MAP_RENDER_OFFSET_Y + (MAP_HEIGHT / 2) * TILE_SIZE - TILE_SIZE, TILE_SIZE * 2 + 6, TILE_SIZE * 2)

    -- -- top
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     -TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)

    -- --bottom
    -- love.graphics.rectangle('fill', MAP_RENDER_OFFSET_X + (MAP_WIDTH / 2) * TILE_SIZE - TILE_SIZE,
    --     VIRTUAL_HEIGHT - TILE_SIZE - 6, TILE_SIZE * 2, TILE_SIZE * 2 + 12)
    
    -- love.graphics.setColor(255, 255, 255, 255)
end

--function Room:updateCamera()
    -- clamp movement of the camera's X/Y between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
--    self.camX = math.max(0,
--        math.min(TILE_SIZE * self.width - VIRTUAL_WIDTH,
--        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

--    self.camY = math.max(0,
--        math.min(TILE_SIZE * self.height - VIRTUAL_HEIGHT,
--        self.player.y - (VIRTUAL_HEIGHT / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
--    self.backgroundX = (self.camX / 3) % 256
--    self.backgroundY = (self.camY / 3) % 256
--end



function Room:updateCamera()
    -- clamp movement of the camera's X/Y between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
    self.camX = math.max(0,
        math.min(TILE_SIZE * self.width - VIRTUAL_WIDTH,
        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

    self.camY = math.max(0,
        math.min(TILE_SIZE * self.height - VIRTUAL_HEIGHT,
        self.player.y - (VIRTUAL_HEIGHT / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
    self.backgroundX = (self.camX / 3) % 256
    self.backgroundY = (self.camY / 3) % 256
end









------------------------------------------------------------------------------------------------
--------- 
------------------------------------------------------------------------------------------------