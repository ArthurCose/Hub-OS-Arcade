local ModDownloader = require("scripts/libs/mod_downloader")

local package_ids = {
  -- chips
  "BattleNetwork6.Class01.Standard.164", -- panel grab
  "BattleNetwork5.Class01.Standard.037", -- crakbom
  "BattleNetwork6.Class01.Standard.074", -- longblde
  -- encounters
  "dev.konstinople.encounter.Tennis",
  "dev.konstinople.encounter.final_destination_multiman",
  "BattleNetwork3.Virus.Boomer",
  "BattleNetwork4.Gaia",
  "BattleNetwork5.Powie",
  -- libraries
  "BattleNetwork6.Libraries.HitDamageJudge",
  "dev.konstinople.library.timers",
  "BattleNetwork.Assets",
  "BattleNetwork.FallingRock",
  "BattleNetwork4.TournamentIntro",
  "BattleNetwork6.Libraries.PanelGrab",
  "dev.konstinople.library.sword",
  "dev.konstinople.library.bomb",
  "dev.konstinople.library.iterator",
  "dev.konstinople.library.ai",
  "dev.konstinople.library.spectator_fun",
  "dev.konstinople.library.ssb",
}

ModDownloader.maintain(package_ids)

-- preload
local preload_ids = {
  "BattleNetwork.Assets",
  "dev.konstinople.library.ssb",
  "dev.konstinople.library.spectator_fun",
  "dev.konstinople.encounter.Tennis"
}

Net:on("player_connect", function(event)
  for _, package_id in ipairs(preload_ids) do
    Net.provide_package_for_player(event.player_id, ModDownloader.resolve_asset_path(package_id))
  end
end)
