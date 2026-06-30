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
  "BattleNetwork4.Bass",
  "BattleNetwork4.FireMan",
  "BattleNetwork5.BlizzardMan",
  "BattleNetwork4.GutsMan",
  "dev.konstinople.encounters.NormalNPC",

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
  "dev.konstinople.library.turn_based",
  "dev.konstinople.library.spectator_fun",
  "dev.konstinople.library.ssb",
  "BattleNetwork6.Statuses.EnemyAlert",

  -- bot libs
  "dev.konstinople.library.chip_jump",
  "BattleNetwork6.Libraries.Buster",
  "BattleNetwork.Emotions",

  -- bot chips
  "BattleNetwork6.Class01.Standard.026", -- BubbleStar1
  "BattleNetwork6.Class01.Standard.027", -- BubbleStar2
  "BattleNetwork6.Class01.Standard.028", -- BubbleStar3
  "BattleNetwork6.Class01.Standard.033", -- ElecPulse1
  "BattleNetwork6.Class01.Standard.034", -- ElecPulse2
  "BattleNetwork6.Class01.Standard.035", -- ElecPulse3
  "BattleNetwork6.Class01.Standard.041", -- RiskyHoney3
  "BattleNetwork6.Class01.Standard.055", -- MachGun1
  "BattleNetwork6.Class01.Standard.056", -- MachGun2
  "BattleNetwork6.Class01.Standard.057", -- MachGun3
  "BattleNetwork4.Class01.Standard.075.Lance",
  "BattleNetwork6.Class01.Standard.121.MegaBoomerang",
  "BattleNetwork6.Class01.Standard.130", -- JusticeOne
  "BattleNetwork6.Class01.Standard.134.Wind",
  "BattleNetwork6.Class01.Standard.124", -- ElecDragon
  "BattleNetwork6.Class01.Standard.125", -- AquaDragon
  "BattleNetwork6.Class01.Standard.126", -- WoodDragon
  "BattleNetwork3.Class01.Standard.160", -- Geddon2
  "BattleNetwork6.Class01.Standard.165", -- AreaGrab
  "BattleNetwork6.Class01.Standard.171", -- Sanctuary
  "BattleNetwork6.Class01.Standard.179", -- Invis
  "BattleNetwork6.Class01.Standard.180.Barrier",
  "BattleNetwork6.Class01.Standard.181.Barrier100",
  "BattleNetwork6.Class01.Standard.182.Barrier200",
  "BattleNetwork6.Class01.Standard.184.LifeAura",
  "BattleNetwork6.Class01.Standard.187", -- ElemTrap
  "BattleNetwork6.Class01.Standard.189", -- AntiDamage
  "BattleNetwork6.Class04.Secret.001",   -- GunDelEX
  "BattleNetwork6.Class02.Mega.003.Roll3",
  "BattleNetwork6.Class02.Mega.006.ProtoSP",
  "BattleNetwork6.Class02.Mega.024.BlastManSP",
  "BattleNetwork6.Class02.Mega.F09.AquaManSP",
  "BattleNetwork6.Class03.Giga.002.Falzar", -- MeteorKnuckle
  "BattleNetwork6.Class03.Giga.004.Gregar", -- ColForce

  -- bot sub dependencies
  "dev.GladeWoodsgrove.library.BarriersAndAuras",
  "BattleNetwork6.Class02.Mega.022.BlastMan",
  "BattleNetwork6.Libraries.ChipNavi",
  "BattleNetwork6.Statuses.BattleHPBug",
  "BattleNetwork6.Class01.Standard.015",
  "BattleNetwork6.Statuses.Bubble",
  "BattleNetwork6.Bugs.CustomHPBug",
  "BattleNetwork6.Class01.Standard.071",
  "BattleNetwork.Evil",
  "BattleNetwork.WindGust",
  "Battle.Helpers",
  "BattleNetwork6.Class02.Mega.001.Roll",
  "BattleNetwork6.Bugs.DamageHPBug",

  -- statuses
  "BattleNetwork6.Statuses.Uninstall",

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
