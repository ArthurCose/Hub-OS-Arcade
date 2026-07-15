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

  local function center_cols()
    local c2 = Field.width() // 2

    if Field.width() % 2 == 1 then
      return c2, c2
    end

    local c1 = c2 - 1
    return c1, c2
  end

  local function team_center_cols()
    return 2, Field.width() - 3
  end

  local list = {
    -- centered cubes
    function()
      local t1, t2 = team_center_cols()

      spawn_rock_cube(t1, Field.height() // 2)
      spawn_rock_cube(t2, Field.height() // 2)
    end,
    -- diagonal cubes
    function()
      local c1, c2 = center_cols()
      spawn_rock_cube(c1, 1)
      spawn_rock_cube(c2, Field.height() - 2)
    end,
    -- diagonals cracked
    function()
      local c1, c2 = center_cols()
      local y2 = Field.height() - 2

      set_state(1, 1, TileState.Cracked)
      set_state(c1, y2, TileState.Cracked)
      set_state(Field.width() - 2, 1, TileState.Cracked)
      set_state(c2, y2, TileState.Cracked)
    end,
    -- corners cracked
    function()
      local c1, c2 = center_cols()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      set_state(1, 1, TileState.Cracked)
      set_state(c1, 1, TileState.Cracked)
      set_state(1, y2, TileState.Cracked)
      set_state(c1, y2, TileState.Cracked)

      set_state(c2, 1, TileState.Cracked)
      set_state(x2, 1, TileState.Cracked)
      set_state(c2, y2, TileState.Cracked)
      set_state(x2, y2, TileState.Cracked)
    end,
    -- back row cracked
    function()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      for y = 1, y2 do
        set_state(1, y, TileState.Cracked)
        set_state(x2, y, TileState.Cracked)
      end
    end,
    -- back row poison
    function()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      for y = 1, y2 do
        set_state(1, y, TileState.Poison)
        set_state(x2, y, TileState.Poison)
      end
    end,
    -- back columns grass
    function()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      for y = 1, y2 do
        set_state(1, y, TileState.Grass)
        set_state(2, y, TileState.Grass)
        set_state(x2 - 1, y, TileState.Grass)
        set_state(x2, y, TileState.Grass)
      end
    end,
    -- diagonal grass patches
    function()
      local x2 = Field.width() - 2

      for i = 1, 2 do
        set_state(1, i, TileState.Grass)
        set_state(2, i, TileState.Grass)
        set_state(x2 - 1, i + 1, TileState.Grass)
        set_state(x2, i + 1, TileState.Grass)
      end
    end,
    -- all grass with rocks
    function()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      for i = 1, 2 do
        set_state(1, i, TileState.Grass)
        set_state(2, i, TileState.Grass)
        set_state(x2 - 1, y2 - i + 1, TileState.Grass)
        set_state(x2, y2 - i + 1, TileState.Grass)
      end

      spawn_boulder(2, 1)
      spawn_boulder(x2 - 1, y2)
    end,
    -- front columns ice
    function()
      local c1, c2 = center_cols()
      local y2 = Field.height() - 2

      for y = 1, y2 do
        set_state(c1 - 1, y, TileState.Ice)
        set_state(c1, y, TileState.Ice)
        set_state(c2, y, TileState.Ice)
        set_state(c2 + 1, y, TileState.Ice)
      end

      if math.random(2) == 1 then
        -- diagonal ice
        spawn_ice_cube(c1, 1)
        spawn_ice_cube(c2, y2)
      end
    end,
    -- back columns ice
    function()
      local x2 = Field.width() - 2
      local y2 = Field.height() - 2

      for y = 1, y2 do
        set_state(1, y, TileState.Ice)
        set_state(2, y, TileState.Ice)
        set_state(x2 - 1, y, TileState.Ice)
        set_state(x2, y, TileState.Ice)
      end

      if math.random(2) == 1 then
        -- centered ice
        local c1, c2 = center_cols()
        local center_y = Field.height() // 2
        spawn_ice_cube(c1 - 1, center_y)
        spawn_ice_cube(c2 + 1, center_y)
      end
    end,
    -- front volcanos
    function()
      local c1, c2 = center_cols()

      for y = 1, Field.height() - 2 do
        set_state(c1, y, TileState.Volcano)
        set_state(c2, y, TileState.Volcano)
      end
    end,
    -- back volcanos
    function()
      local x2 = Field.width() - 2

      for y = 1, Field.height() - 2 do
        set_state(1, y, TileState.Volcano)
        set_state(x2, y, TileState.Volcano)
      end
    end,
    -- center hole
    function()
      local t1, t2 = team_center_cols()
      local center_y = Field.height() // 2

      set_state(t1, center_y, TileState.PermaHole)
      set_state(t2, center_y, TileState.PermaHole)
    end,
    -- opposing front hole
    function()
      local c1, c2 = center_cols()
      local y2 = Field.height() - 2

      set_state(c1, 1, TileState.PermaHole)
      set_state(c2, y2, TileState.PermaHole)
    end,
    -- center holy
    function()
      local t1, t2 = team_center_cols()
      local center_y = Field.height() // 2

      set_state(t1, center_y, TileState.Holy)
      set_state(t2, center_y, TileState.Holy)
    end,
    -- front holy
    function()
      local c1, c2 = center_cols()

      for y = 1, Field.height() - 2 do
        set_state(c1, y, TileState.Holy)
        set_state(c2, y, TileState.Holy)
      end
    end,

    -- custom
    -- front sea
    function()
      local c1, c2 = center_cols()

      for y = 1, Field.height() - 2 do
        set_state(c1, y, TileState.Sea)
        set_state(c2, y, TileState.Sea)
      end
    end
  }

  list[math.random(#list)]()
end

function Lib.create_player_spawn_resolver()
  local spawn_pattern

  if Field.width() == 8 and Field.height() == 5 then
    spawn_pattern = {
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
  else
    -- generate a pattern that looks like: >>
    spawn_pattern = {}

    local w = Field.width()
    local h = Field.height()

    local function push_position(x, y)
      if y > 0 and x > 0 and x < w - 1 and y < h - 1 then
        spawn_pattern[#spawn_pattern + 1] = { x, y }
      end
    end

    local cx = w // 2 - 1
    local cy = h // 2

    local start_x = cx - 1
    local lead_x = start_x

    while true do
      push_position(lead_x, cy)

      for offset = 1, math.min(lead_x, cy) do
        push_position(lead_x - offset, cy + offset)
        push_position(lead_x - offset, cy - offset)
      end

      lead_x = lead_x - 1

      if lead_x == start_x then
        break
      end

      if lead_x < 1 then
        lead_x = cx + cy
      end
    end
  end

  local red_attempts = 0
  local blue_attempts = 0

  ---@param team Team
  return function(team)
    local MAX_FAILS = (Field.width() - 2) * (Field.height() - 2)
    local fails = 0

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
        x = Field.width() - 1 - x
      end

      local tile = Field.tile_at(x, y)

      if not tile then
        goto continue
      end

      if fails > MAX_FAILS or (tile:is_walkable() and not tile:is_reserved()) then
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

      fails = fails + 1
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
function Lib.apply_pvp_rules(encounter, data)
  local custom_config = data and data.custom_config or {}

  encounter:set_turn_limit(custom_config.turn_limit or 15)

  if custom_config.tfc_limit == "1/Plyr" then
    encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.PerEntity(1))
  elseif custom_config.tfc_limit == "1/Team" then
    encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.PerTeam(1))
  else
    encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.Unlimited)
  end

  if custom_config.select_time then
    Timers.CardSelectTimer.MAX_TIME = custom_config.select_time * 60
  end

  if custom_config.damage_multiplier and custom_config.damage_multiplier ~= 1 then
    local artifact = Artifact.new()

    artifact.on_update_func = function()
      Field.find_players(function(player)
        local expr = "DAMAGE * " .. (custom_config.damage_multiplier - 1)
        local aux_prop = AuxProp.new():increase_pre_hit_damage(expr)
        player:add_aux_prop(aux_prop)
        return false
      end)
      artifact:delete()
    end

    Field.spawn(artifact, 0, 0)
  end

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
