local HitDamageJudge = require("BattleNetwork6.Libraries.HitDamageJudge")
local SpectatorFun = require("dev.konstinople.library.spectator_fun")
local Timers = require("dev.konstinople.library.timers")

---@class dev.konstinople.library.arcade_fields
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
  -- delay most tile state changes to prevent overwrite from stage augments
  ---@type [number, number, TileState][]
  local pending_tile_state_changes = {}

  local state_delay = 5
  local artifact = Artifact.new()
  artifact:create_component(Lifetime.Scene).on_update_func = function()
    state_delay = state_delay - 1

    if state_delay > 0 then
      return
    end

    artifact:delete()

    for _, change in ipairs(pending_tile_state_changes) do
      local x, y, state = table.unpack(change)
      local tile = Field.tile_at(x, y)

      if tile then
        tile:set_state(state)
      end
    end
  end

  Field.spawn(artifact, 0, 0)

  -- helper functions
  local function set_state(x, y, state)
    if state ~= TileState.PermaHole and state ~= TileState.Cracked then
      pending_tile_state_changes[#pending_tile_state_changes + 1] = { x, y, state }
      return
    end

    local tile = Field.tile_at(x, y)

    if tile then
      tile:set_state(state)
    end
  end

  local function spawn_obstacle(x, y, constructor)
    local tile = Field.tile_at(x, y)

    if not tile then
      return
    end

    ---@type Entity
    local obstacle = constructor()
    obstacle:set_team(Team.Other)
    obstacle:set_owner(Team.Other)
    Field.spawn(obstacle, tile)

    -- reserve the tile before the cube is spawned
    tile:reserve_for(obstacle)

    -- make sure to clean up the reservation
    local action = Action.new(obstacle)
    action.on_action_end_func = function()
      tile:remove_reservation_for(obstacle)
    end

    obstacle:queue_action(action)
  end

  local function spawn_rock_cube(x, y)
    spawn_obstacle(x, y, function()
      local CubesAndBouldersLib = require("BattleNetwork6.Libraries.CubesAndBoulders")
      return CubesAndBouldersLib.new_rock_cube():create_obstacle()
    end)
  end

  local function spawn_ice_cube(x, y)
    spawn_obstacle(x, y, function()
      local CubesAndBouldersLib = require("BattleNetwork6.Libraries.CubesAndBoulders")
      return CubesAndBouldersLib.new_ice_cube():create_obstacle()
    end)
  end

  local function spawn_boulder(x, y)
    spawn_obstacle(x, y, function()
      local CubesAndBouldersLib = require("BattleNetwork6.Libraries.CubesAndBoulders")
      return CubesAndBouldersLib.new_boulder():create_obstacle()
    end)
  end

  local list = {
    -- centered cubes
    function()
      spawn_rock_cube(2, 2)
      spawn_rock_cube(5, 2)
    end,
    -- diagonal cubes
    function()
      spawn_rock_cube(3, 1)
      spawn_rock_cube(4, 3)
    end,
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
      set_state(4, 3, TileState.Cracked)
      set_state(6, 3, TileState.Cracked)
    end,
    -- back row cracked
    function()
      for y = 1, 3 do
        set_state(1, y, TileState.Cracked)
        set_state(6, y, TileState.Cracked)
      end
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
    -- all grass with rocks
    function()
      for i = 1, 2 do
        set_state(1, i, TileState.Grass)
        set_state(2, i, TileState.Grass)
        set_state(5, i + 1, TileState.Grass)
        set_state(6, i + 1, TileState.Grass)
      end

      spawn_boulder(2, 1)
      spawn_boulder(5, 3)
    end,
    -- front columns ice
    function()
      for y = 1, 3 do
        set_state(2, y, TileState.Ice)
        set_state(3, y, TileState.Ice)
        set_state(4, y, TileState.Ice)
        set_state(5, y, TileState.Ice)
      end

      if math.random(2) == 1 then
        -- diagonal ice
        spawn_ice_cube(3, 1)
        spawn_ice_cube(4, 3)
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

      if math.random(2) == 1 then
        -- centered ice
        spawn_ice_cube(2, 2)
        spawn_ice_cube(5, 2)
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

function Lib.create_player_spawn_resolver()
  local spawn_pattern = {
    { 2, 2 }, -- center
    { 1, 3 }, -- bottom left
    { 1, 1 }, -- top left
    { 3, 3 }, -- bottom right
    { 3, 1 }, -- top right
    { 1, 2 }, -- back
    { 3, 2 }, -- front
    { 2, 1 }, -- top
    { 2, 3 }, -- bottom
  }

  local red_attempts = 0
  local blue_attempts = 0

  ---@param team Team
  return function(team)
    while true do
      local spawn_index

      if team == Team.Blue then
        spawn_index = blue_attempts
        blue_attempts = blue_attempts + 1
      else
        spawn_index = red_attempts
        red_attempts = red_attempts + 1
      end

      spawn_index = spawn_index % #spawn_pattern + 1

      local position = spawn_pattern[spawn_index]
      local x, y = position[1], position[2]

      if team == Team.Blue then
        -- mirror
        x = 7 - x
      end

      local tile = Field.tile_at(x, y)

      if not tile then
        goto continue
      end

      if tile:is_walkable() and not tile:is_reserved() then
        return x, y
      end

      if team == Team.Blue then
        tile = tile:get_tile(Direction.Right, 1)
      else
        tile = tile:get_tile(Direction.Left, 1)
      end

      if tile and tile:is_walkable() and not tile:is_reserved() then
        return tile:x(), tile:y()
      end

      ::continue::
    end
  end
end

---@param encounter Encounter
---@param teams { team: string, player_count: number }[]
---@param callback fun(index: number, team_name: string?)
local function for_players_in_teams(encounter, teams, callback)
  local team = teams[1]
  local remaining = (team and team.player_count) or 0
  local next_team_i = 2

  for i = 0, encounter:player_count() - 1 do
    while team and remaining == 0 do
      team = teams[next_team_i]
      next_team_i = next_team_i + 1

      if team then
        remaining = team.player_count
      end
    end

    callback(i, team and team.team)
    remaining = remaining - 1
  end
end

---@param encounter Encounter
function Lib.spawn_players(encounter, data)
  local active_player_count = 0
  local resolve_spawn = Lib.create_player_spawn_resolver()

  for_players_in_teams(encounter, data.teams, function(i, team_name)
    if team_name == "red" or team_name == "blue" then
      local team

      if team_name == "blue" then
        team = Team.Blue
      else
        team = Team.Red
      end

      local x, y = resolve_spawn(team)
      encounter:spawn_player(i, x, y)
    else
      encounter:mark_spectator(i)
    end
  end)

  if active_player_count > 2 then
    -- prevent enemy teams from owning certain columns in a multibattle
    -- set to Team.Other instead

    local artifact = Artifact.new()
    local component = artifact:create_component(Lifetime.Scene)
    component.on_update_func = function()
      local function neutralize_column(x)
        for y = 0, Field.height() - 1 do
          local tile = Field.tile_at(x, y)

          if tile and tile:team() ~= tile:original_team() and tile:team() ~= Team.Other then
            tile:set_team(Team.Other, tile:facing())
          end
        end
      end

      neutralize_column(2)
      neutralize_column(Field.width() - 3)
    end
  end

  return active_player_count
end

---@param encounter Encounter
function Lib.apply_pvp_rules(encounter)
  encounter:set_turn_limit(15)
  encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.Unlimited)
  HitDamageJudge.init(encounter)
  SpectatorFun.init(encounter)

  Timers.AfkTimer.init(encounter)
  Timers.CardSelectTimer.init(encounter)
  Timers.TurnTimer.init(encounter)

  encounter:set_spectate_on_delete(true)

  encounter:on_disconnect_recommendation(function(index)
    local found_player = false

    Field.find_players(function(entity)
      if entity:player_index() == index then
        found_player = true
        entity:on_delete(function()
          encounter:disconnect_input(index)
        end)
      end

      return false
    end)

    if not found_player then
      encounter:disconnect_input(index)
    end
  end)


  -- by LDR's request
  encounter:set_entities_share_ownership(false)
end

return Lib
