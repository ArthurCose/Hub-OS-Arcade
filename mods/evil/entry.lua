local TournamentIntro = require("BattleNetwork4.TournamentIntro")
---@type dev.konstinople.library.arcade_fields
local ArcadeFields = require("dev.konstinople.library.arcade_fields")
local Evil = require("evil")

---@param encounter Encounter
local function set_ambience(encounter)
  local bgs = {
    "backgrounds/dark_generic_comp",
    "backgrounds/duo_battle",
    "backgrounds/undernet",
  }
  local bg = bgs[math.random(#bgs)]
  encounter:set_background(bg .. ".png", bg .. ".animation")
end

---@param encounter Encounter
function encounter_init(encounter, data)
  ArcadeFields.apply_pvp_rules(encounter)
  set_ambience(encounter)
  Evil.init()
  ArcadeFields.randomize_field()
  ArcadeFields.spawn_players(encounter, data)

  -- purple tournament intro
  TournamentIntro.LINE_COLOR = Color.new(140, 0, 255)
  TournamentIntro.init()
end
