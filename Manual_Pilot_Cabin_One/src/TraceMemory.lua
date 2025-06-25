TraceMemory = Class{}

function TraceMemory:init(player)
    self.x = player.x
    self.y = player.y
    self.timer = 0
    --self.width = width
    --self.height = height
    self.memorized_cosmos_tiles = {} -- Collection Traced Tiles

function TraceFormer:update(dt)

    self.timer = self.timer + dt
    self.timer = self.timer % 60

    --self.x = self.x % MAP_WIDTH
    --self.y = self.y % MAP_HEIGHT

    local id = TILE_EMPTY

    if self.x == 1 and self.y == 1 then
        id = TILE_TOP_LEFT_CORNER
    elseif self.x == 1 and self.y == self.height then
        id = TILE_BOTTOM_LEFT_CORNER
    elseif self.x == self.width and self.y == 1 then
        id = TILE_TOP_RIGHT_CORNER
    elseif self.x == self.width and self.y == self.height then
        id = TILE_BOTTOM_RIGHT_CORNER
    
    -- random left-hand walls, right walls, top, bottom, and floors
    elseif self.x == 1 then
        id = TILE_LEFT_WALLS[math.random(#TILE_LEFT_WALLS)]
    elseif self.x == self.width then
        id = TILE_RIGHT_WALLS[math.random(#TILE_RIGHT_WALLS)]
    elseif self.y == 1 then
        id = TILE_TOP_WALLS[math.random(#TILE_TOP_WALLS)]
    elseif self.y == self.height then
        id = TILE_BOTTOM_WALLS[math.random(#TILE_BOTTOM_WALLS)]
    else
        id = TILE_FLOORS[math.random(#TILE_FLOORS)]
    end
    
    table.insert(self.memorized_cosmos_tiles, {
        id = id, timer})

    self.timer = self.timer + dt
    self.timer = self.timer % 20

    -- Memory-span of 20 seconds
    if self.timer == 15 then
        --table.delete(self.memorized_cosmos_tiles, {
        --    -1})
        table.remove(self.memorized_cosmos_tiles, self.memorized_cosmos_tiles[#self.memorized_cosmos_tiles])
    end
end

function TraceMemory:generateTrace()
    self.x = player.x
    self.y = player.y
    self.timer = 0
    --self.width = width
    --self.height = height
    return self.memorized_cosmos_tiles
end

--    self.memorized_cosmos_tiles = {} -- Collection Traced Tiles
--    table.insert(self.memorized_cosmos_tiles, self.tiles[])
--     = self.x % MAP_WIDTH
--     = self.y % MAP_HEIGHT   
--    function TraceMemory:TileStorer(player)
--    self.x

-- essential addition
-- code complete --
-- prepare ML integration
-- DRL ? <---

