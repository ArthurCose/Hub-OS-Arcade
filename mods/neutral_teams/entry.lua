local TournamentIntro = require("BattleNetwork4.TournamentIntro")
---@type dev.konstinople.library.arcade_fields
local ArcadeFields = require("dev.konstinople.library.arcade_fields")

---@param encounter Encounter
function encounter_init(encounter, data)
  ArcadeFields.apply_pvp_rules(encounter)
  ArcadeFields.randomize_ambience(encounter)
  ArcadeFields.spawn_players(encounter, data)

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

  -- temp set the teams for a visual
  Field.tile_at(2, 2):set_team(Team.Red, Direction.Right)
  Field.tile_at(5, 2):set_team(Team.Blue, Direction.Left)

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

    -- fix teams
    Field.find_players(function(player)
      if player:team() == Team.Other then
        if player:current_tile():x() > half_width then
          player:set_team(Team.Red)
        else
          player:set_team(Team.Blue)
        end
      end

      return false
    end)
  end

  -- by LDR's request
  encounter:set_entities_share_ownership(false)

  -- display white tournament intro
  TournamentIntro.LINE_COLOR = Color.new(255, 255, 255)
  TournamentIntro.init()
end
