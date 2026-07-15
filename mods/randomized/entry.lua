local TournamentIntro = require("BattleNetwork4.TournamentIntro")
---@type dev.konstinople.library.arcade_fields
local ArcadeFields = require("dev.konstinople.library.arcade_fields")

---@param encounter Encounter
function encounter_init(encounter, data)
  if data and data.custom_config then
    encounter:set_field_size(
      data.custom_config.field_width + 2,
      data.custom_config.field_height + 2
    )
  end

  ArcadeFields.apply_pvp_rules(encounter, data)

  if not data or not data.custom_config or data.custom_config.randomize then
    ArcadeFields.randomize_field()
  end

  ArcadeFields.randomize_ambience(encounter)
  ArcadeFields.spawn_players(encounter, data)

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
