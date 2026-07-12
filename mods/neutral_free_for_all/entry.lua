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

  encounter:enable_scripted_result()

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

      player_count = player_count + 1

      return false
    end)

    if has_local and player_count == 1 then
      encounter:win()
    elseif player_count <= 1 then
      encounter:lose()
    end

    if player_count == 0 then
      encounter:end_scene()
    end
  end

  -- display white tournament intro
  TournamentIntro.LINE_COLOR = Color.new(255, 255, 255)
  TournamentIntro.init()
end
