local ModDownloader = require("scripts/libs/mod_downloader")

local package_ids = {
  -- chips
  "BattleNetwork6.Class01.Standard.164", -- panel grab
  "BattleNetwork5.Class01.Standard.037", -- crakbom
  "BattleNetwork6.Class01.Standard.074", -- longblde
  "BattleNetwork6.Class01.Standard.177", -- buster up
  -- encounters
  "dev.konstinople.encounter.Tennis",
  "dev.konstinople.encounter.final_destination_multiman",
  "BattleNetwork3.Virus.Boomer",
  "BattleNetwork4.Gaia",
  "BattleNetwork5.Powie",
  -- tile states
  "BattleNetwork5.TileStates.Sea",
  "BattleNetwork6.TileStates.Ice",
  "BattleNetwork6.TileStates.Poison",
  "BattleNetwork6.TileStates.Volcano",
  "BattleNetwork6.TileStates.Holy",
  "BattleNetwork6.TileStates.Grass",
  -- libraries
  "BattleNetwork6.Libraries.HitDamageJudge",
  "dev.konstinople.library.timers",
  "BattleNetwork.Assets",
  "BattleNetwork.FallingRock",
  "BattleNetwork4.TournamentIntro",
  "BattleNetwork6.Libraries.PanelGrab",
  "BattleNetwork6.Libraries.CubesAndBoulders",
  "dev.konstinople.library.sliding_obstacle",
  "dev.konstinople.library.sword",
  "dev.konstinople.library.bomb",
  "dev.konstinople.library.iterator",
  "dev.konstinople.library.ai",
  "dev.konstinople.library.spectator_fun",
  "dev.konstinople.library.ssb",

  -- bugs
  "BattleNetwork.Bugs.EmotionFlicker",
  "BattleNetwork4.Bugs.ForwardMovement",
  "BattleNetwork4.Bugs.BackwardMovement",
  "BattleNetwork6.Bugs.BattleHPBug",
  "BattleNetwork6.Bugs.BusterBug",
  "BattleNetwork6.Bugs.BusterJam",
  "BattleNetwork6.Bugs.EmotionBug",
  "BattleNetwork6.Bugs.PanelBug",
  "BattleNetwork6.Bugs.WarpStep",
}

ModDownloader.maintain(package_ids)

-- preload
local preload_ids = {
  "BattleNetwork.Assets",
  "dev.konstinople.library.ssb",
  "dev.konstinople.library.spectator_fun"
}

Net:on("player_connect", function(event)
  for _, package_id in ipairs(preload_ids) do
    Net.provide_package_for_player(event.player_id, ModDownloader.resolve_asset_path(package_id))
  end
end)
