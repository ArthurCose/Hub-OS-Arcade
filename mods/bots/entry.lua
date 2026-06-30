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

local red_attempts = 0
local blue_attempts = 0

---@param team Team
local function resolve_spawn(team)
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

local rank_pool = {
  Rank.V1,
  Rank.V2, -- uninstalls
  Rank.V3, -- paralyzes
}
local recycle_pool = {}

local function pluck_rank()
  if #rank_pool == 0 then
    -- cycle pools
    rank_pool, recycle_pool = recycle_pool, rank_pool
  end

  local rank = table.remove(rank_pool, math.random(#rank_pool))
  recycle_pool[#recycle_pool + 1] = rank
  return rank
end

---@param team Team
---@param count number
local function spawn_bots(team, count)
  for i = 1, count do
    local rank = pluck_rank()
    local x, y = resolve_spawn(team)
    local bot = Character.from_package("dev.konstinople.enemies.NormalNPC", team, rank)
    Field.spawn(bot, x, y)
  end
end

---@param encounter Encounter
function encounter_init(encounter, data)
  ArcadeFields.randomize_field()
  ArcadeFields.randomize_ambience(encounter)

  encounter:set_turn_limit(15)
  encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.Unlimited)
  HitDamageJudge.init(encounter)
  SpectatorFun.init(encounter)

  Timers.AfkTimer.init(encounter)
  Timers.CardSelectTimer.init(encounter)
  Timers.TurnTimer.init(encounter)

  encounter:set_spectate_on_delete(true)

  local red_players = 0
  local blue_players = 0

  -- spawn players
  for_players_in_teams(encounter, data.teams, function(i, team_name)
    if team_name == "red" or team_name == "blue" then
      local team

      if team_name == "blue" then
        team = Team.Blue
        blue_players = blue_players + 1
      else
        team = Team.Red
        red_players = red_players + 1
      end

      local x, y = resolve_spawn(team)
      encounter:spawn_player(i, x, y)
    else
      encounter:mark_spectator(i)
    end
  end)

  -- spawn bots
  if red_players == blue_players then
    spawn_bots(Team.Red, 1)
    spawn_bots(Team.Blue, 1)
  else
    local bot_team

    if red_players < blue_players then
      bot_team = Team.Red
    else
      bot_team = Team.Blue
    end

    spawn_bots(bot_team, math.abs(red_players - blue_players))
  end

  if red_players + blue_players > 2 then
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

  -- by LDR's request
  encounter:set_entities_share_ownership(false)

  -- neon tournament intro
  local colors = {
    Color.new(255, 0, 255), -- magenta
    Color.new(0, 255, 255), -- cyan
    Color.new(255, 255, 0), -- yellow
    Color.new(0, 255, 0),   -- green
  }
  TournamentIntro.LINE_COLOR = colors[math.random(#colors)]
  TournamentIntro.init()
end
