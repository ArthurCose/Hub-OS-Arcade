local TournamentIntro = require("BattleNetwork4.TournamentIntro")
---@type dev.konstinople.library.arcade_fields
local ArcadeFields = require("dev.konstinople.library.arcade_fields")

---@param encounter Encounter
function encounter_init(encounter, data)
  ArcadeFields.apply_pvp_rules(encounter)
  encounter:set_time_freeze_chain_limit(TimeFreezeChainLimit.PerEntity(1))

  ArcadeFields.randomize_field()
  ArcadeFields.randomize_ambience(encounter)
  ArcadeFields.spawn_players(encounter, data)

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
