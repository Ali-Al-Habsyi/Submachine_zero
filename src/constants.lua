--[[
    GD50
    Legend of Zelda

    -- constants --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

VIRTUAL_WIDTH = 384
VIRTUAL_HEIGHT = 216

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

TILE_SIZE = 16

--
-- entity constants
--
PLAYER_WALK_SPEED = 60

PROJECTILE_SPEED = 200
PROJECTILE_MAX_TILES = 4

-- APPROACH MACHINE COMPUTABILITY
--
-- map constants
--
MAP_WIDTH_AMPLIFIER = 3
MAP_HEIGHT_AMPLIFIER = 3
MAP_WIDTH = MAP_WIDTH_AMPLIFIER * VIRTUAL_WIDTH / TILE_SIZE - 2
MAP_HEIGHT = MAP_HEIGHT_AMPLIFIER * math.floor(VIRTUAL_HEIGHT / TILE_SIZE) - 2

MAP_RENDER_OFFSET_X = (VIRTUAL_WIDTH - (MAP_WIDTH * TILE_SIZE)) / 2
MAP_RENDER_OFFSET_Y = (VIRTUAL_HEIGHT - (MAP_HEIGHT * TILE_SIZE)) / 2

--
-- tile IDs
--
TILE_TOP_LEFT_CORNER = 4
TILE_TOP_RIGHT_CORNER = 5
TILE_BOTTOM_LEFT_CORNER = 23
TILE_BOTTOM_RIGHT_CORNER = 24

TILE_EMPTY = 19

TILE_FLOORS = {
    7, 8, 9, 10, 11, 12, 13,
    26, 27, 28, 29, 30, 31, 32,
    45, 46, 47, 48, 49, 50, 51,
    64, 65, 66, 67, 68, 69, 70,
    88, 89, 107, 108
}

TILE_TOP_WALLS = {58, 59, 60}
TILE_BOTTOM_WALLS = {79, 80, 81}
TILE_LEFT_WALLS = {77, 96, 115}
TILE_RIGHT_WALLS = {78, 97, 116}





COSMOS_TILE_SIZE = 20

TILE_TOP_LEFT_CORNER = 4
TILE_TOP_RIGHT_CORNER = 5
TILE_BOTTOM_LEFT_CORNER = 23
TILE_BOTTOM_RIGHT_CORNER = 24

COSMOS_TILE_TOP_WALLS = {58, 59, 60}
COSMOS_TILE_BOTTOM_WALLS = {79, 80, 81}
COSMOS_TILE_LEFT_WALLS = {77, 96, 115}
TILE_RIGHT_WALLS = {78, 97, 116}

COSMOS_TILE_FLOORS = {
    7, 8, 9, 10, 11, 12, 13,
    26, 27, 28, 29, 30, 31, 32,
    45, 46, 47, 48, 49, 50, 51,
    64, 65, 66, 67, 68, 69, 70,
    88, 89, 107, 108
}




