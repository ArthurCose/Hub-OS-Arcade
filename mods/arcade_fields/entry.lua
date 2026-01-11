local Lib = {}


---@param encounter Encounter
function Lib.randomize_ambience(encounter)
  local bgs = {
    { "backgrounds/anime.png",          "backgrounds/anime.animation" },
    { "backgrounds/crowd_blue.png",     "backgrounds/crowd.animation" },
    { "backgrounds/mmsf1_final_BG.png", "backgrounds/mmsf1_final_BG.animation" },
    { "backgrounds/RoboControlPC.png",  "backgrounds/RoboControlPC.animation" }
  }
  local bg = bgs[math.random(#bgs)]
  encounter:set_background(bg[1], bg[2])
end

function Lib.randomize_field()
  local function set_state(x, y, state)
    local tile = Field.tile_at(x, y)

    if tile then
      tile:set_state(state)
    end
  end

  local list = {
    -- diagonals cracked
    function()
      set_state(1, 1, TileState.Cracked)
      set_state(3, 3, TileState.Cracked)
      set_state(6, 1, TileState.Cracked)
      set_state(4, 3, TileState.Cracked)
    end,
    -- corners cracked
    function()
      set_state(1, 1, TileState.Cracked)
      set_state(3, 1, TileState.Cracked)
      set_state(1, 3, TileState.Cracked)
      set_state(3, 3, TileState.Cracked)

      set_state(4, 1, TileState.Cracked)
      set_state(6, 1, TileState.Cracked)
      set_state(4, 6, TileState.Cracked)
      set_state(6, 6, TileState.Cracked)
    end,
    -- back row poison
    function()
      for y = 1, 3 do
        set_state(1, y, TileState.Poison)
        set_state(6, y, TileState.Poison)
      end
    end,
    -- back columns grass
    function()
      for y = 1, 3 do
        set_state(1, y, TileState.Grass)
        set_state(2, y, TileState.Grass)
        set_state(5, y, TileState.Grass)
        set_state(6, y, TileState.Grass)
      end
    end,
    -- diagonal grass patches
    function()
      for i = 1, 2 do
        set_state(1, i, TileState.Grass)
        set_state(2, i, TileState.Grass)
        set_state(5, i + 1, TileState.Grass)
        set_state(6, i + 1, TileState.Grass)
      end
    end,
    -- front columns ice
    function()
      for y = 1, 3 do
        set_state(2, y, TileState.Ice)
        set_state(3, y, TileState.Ice)
        set_state(4, y, TileState.Ice)
        set_state(5, y, TileState.Ice)
      end
    end,
    -- back columns ice
    function()
      for y = 1, 3 do
        set_state(1, y, TileState.Ice)
        set_state(2, y, TileState.Ice)
        set_state(5, y, TileState.Ice)
        set_state(6, y, TileState.Ice)
      end
    end,
    -- front volcanos
    function()
      for y = 1, 3 do
        set_state(3, y, TileState.Volcano)
        set_state(4, y, TileState.Volcano)
      end
    end,
    -- back volcanos
    function()
      for y = 1, 3 do
        set_state(1, y, TileState.Volcano)
        set_state(6, y, TileState.Volcano)
      end
    end,
    -- center hole
    function()
      set_state(2, 2, TileState.PermaHole)
      set_state(5, 2, TileState.PermaHole)
    end,
    -- opposing front hole
    function()
      set_state(3, 1, TileState.PermaHole)
      set_state(4, 3, TileState.PermaHole)
    end,
    -- center holy
    function()
      set_state(2, 2, TileState.Holy)
      set_state(5, 2, TileState.Holy)
    end,
    -- front holy
    function()
      for y = 1, 3 do
        set_state(3, y, TileState.Holy)
        set_state(4, y, TileState.Holy)
      end
    end,

    -- custom
    -- front sea
    function()
      for y = 1, 3 do
        set_state(3, y, TileState.Sea)
        set_state(4, y, TileState.Sea)
      end
    end
  }

  list[math.random(#list)]()
end

return Lib
