local HitDamageJudge = require("BattleNetwork6.Libraries.HitDamageJudge")
local SpectatorFun = require("dev.konstinople.library.spectator_fun")
local Timers = require("dev.konstinople.library.timers")
local TournamentIntro = require("BattleNetwork4.TournamentIntro")
local ArcadeFields = require("dev.konstinople.library.arcade_fields")

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
function encounter_init(encounter, data)
  ArcadeFields.randomize_ambience(encounter)

  encounter:set_turn_limit(15)
  encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.Unlimited)
  HitDamageJudge.init(encounter)
  SpectatorFun.init(encounter)

  Timers.AfkTimer.init(encounter)
  Timers.CardSelectTimer.init(encounter)
  Timers.TurnTimer.init(encounter)

  encounter:set_spectate_on_delete(true)

  local red_attempts = 0
  local blue_attempts = 0
  local spectating = false

  for_players_in_teams(encounter, data.teams, function(i, team_name)
    if team_name == "red" or team_name == "blue" then
      local spawn_index = i
      local is_blue = team_name == "blue"

      while true do
        if is_blue then
          spawn_index = blue_attempts
          blue_attempts = blue_attempts + 1
        else
          spawn_index = red_attempts
          red_attempts = red_attempts + 1
        end

        spawn_index = spawn_index % #spawn_pattern + 1

        local position = spawn_pattern[spawn_index]
        local x, y = position[1], position[2]

        if is_blue then
          -- mirror
          x = 7 - x
        end

        local tile = Field.tile_at(x, y)

        if not tile then
          goto continue
        end

        if tile:is_walkable() and not tile:is_reserved() then
          encounter:spawn_player(i, x, y)
          break
        end

        if is_blue then
          tile = tile:get_tile(Direction.Right, 1)
        else
          tile = tile:get_tile(Direction.Left, 1)
        end

        if tile and tile:is_walkable() and not tile:is_reserved() then
          encounter:spawn_player(i, tile:x(), tile:y())
          break
        end

        ::continue::
      end
    else
      encounter:mark_spectator(i)

      if Resources.is_local(i) then
        spectating = true
      end
    end
  end)

  -- set all panels to Team.Other
  local w = Field.width()
  local h = Field.height()
  local half_width = (w - 1) // 2
  for x = 0, w - 1 do
    local direction = Direction.Right

    if x > half_width then
      direction = Direction.Left
    end

    for y = 0, h - 1 do
      Field.tile_at(x, y):set_team(Team.Other, direction)
    end
  end

  encounter:enable_scripted_result()

  -- prevent players from hitting themselves
  ---@type fun()?
  local init = function()
    Field.find_players(function(player)
      local defense_rule = DefenseRule.new(DefensePriority.First or 0, DefenseOrder.Always)

      defense_rule.defense_func = function(defense, _, _, hit_props)
        if hit_props.context.aggressor == player:id() then
          defense:block_damage()
          defense:set_responded()
        end
      end

      player:add_defense_rule(defense_rule)

      return false
    end)
  end

  -- prevent any attempts at tile ownership
  local artifact = Artifact.new()
  local component = artifact:create_component(Lifetime.Scene)
  component.on_update_func = function()
    for x = 0, Field.width() - 1 do
      for y = 0, Field.height() - 1 do
        local tile = Field.tile_at(x, y)

        if tile and tile:team() ~= tile:original_team() then
          tile:set_team(Team.Other, tile:original_facing())
        end
      end
    end

    -- detect win
    local player_count = 0
    local has_local = nil
    Field.find_players(function(player)
      if player:is_local() then
        has_local = true
      end

      return false
    end)

    if spectating then
      if player_count == 0 then
        encounter:lose()
      end
    else
      if not has_local then
        encounter:lose()
      elseif player_count == 1 then
        encounter:win()
      end
    end

    if init then
      init()
      init = nil
    end
  end

  -- by LDR's request
  encounter:set_entities_share_ownership(false)

  -- display white tournament intro
  TournamentIntro.LINE_COLOR = Color.new(255, 255, 255)
  TournamentIntro.init()
end
