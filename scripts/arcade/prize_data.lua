local BASE_VIRUS = 200
local SPECIAL_VIRUS = 500

---@class Arcade.PrizeData
---@field id string
---@field name string
---@field state string
---@field price number

local PRIZE_LIST = {
  {
    name = "LuckyCat",
    state = "Lucky_Cat",
    price = 1
  },
  {
    name = "TinMan",
    state = "Tin_Man",
    price = 1
  },
  {
    id = "WizardDog",
    name = "WzrdDog",
    state = "Wizard_Dog",
    price = 50
  },
  {
    name = "Rabbit",
    state = "Rabbit",
    price = 60
  },
  {
    name = "Duck",
    state = "Duck",
    price = 80
  },
  {
    name = "TeddyBear",
    state = "Teddy_Bear",
    price = 100
  },
  {
    id = "BunnyBear",
    name = "BunnBear",
    state = "Bunny_Bear",
    price = 100
  },
  {
    name = "Mettaur",
    state = "Mettaur",
    price = BASE_VIRUS
  },
  {
    name = "Mettaur2",
    state = "Mettaur2",
    price = SPECIAL_VIRUS
  },
  {
    name = "Mettaur3",
    state = "Mettaur3",
    price = SPECIAL_VIRUS
  },
  {
    id = "Mettaur3EX",
    name = "Mettaur3",
    state = "Mettaur3_EX",
    price = SPECIAL_VIRUS
  },
  {
    name = "Mushy",
    state = "Mushy",
    price = BASE_VIRUS
  },
  {
    name = "Mashy",
    state = "Mashy",
    price = SPECIAL_VIRUS
  },
  {
    name = "Moshy",
    state = "Moshy",
    price = SPECIAL_VIRUS
  },
  {
    id = "MushyOmega",
    name = "MushyΩ",
    state = "Mushy_Omega",
    price = SPECIAL_VIRUS
  },
  {
    name = "Swordy",
    state = "Swordy",
    price = BASE_VIRUS
  },
  {
    name = "Swordy2",
    state = "Swordy2",
    price = SPECIAL_VIRUS
  },
  {
    name = "Swordy3",
    state = "Swordy3",
    price = SPECIAL_VIRUS
  },
  {
    id = "SwordyOmega",
    name = "SwordyΩ",
    state = "Swordy_Omega",
    price = SPECIAL_VIRUS
  },
  {
    name = "Spikey",
    state = "Spikey",
    price = BASE_VIRUS
  },
  {
    name = "Spikey2",
    state = "Spikey2",
    price = SPECIAL_VIRUS
  },
  {
    name = "Spikey3",
    state = "Spikey3",
    price = SPECIAL_VIRUS
  },
  {
    id = "SpikeyOmega",
    name = "SpikeyΩ",
    state = "Spikey_Omega",
    price = SPECIAL_VIRUS
  },
  {
    name = "Scuttle",
    state = "Scuttle",
    price = BASE_VIRUS
  },
  {
    name = "Scutz",
    state = "Scutz",
    price = BASE_VIRUS
  },
  {
    name = "Scuttler",
    state = "Scuttler",
    price = BASE_VIRUS
  },
  {
    name = "Scuttzer",
    state = "Scuttzer",
    price = BASE_VIRUS
  },
  {
    name = "Scuttlest",
    state = "Scuttlest",
    price = SPECIAL_VIRUS
  },
  {
    id = "ScuttleOmega",
    name = "ScuttleΩ",
    state = "Scuttle_Omega",
    price = SPECIAL_VIRUS
  },
}

local PRIZE_MAP = {}

for _, prize in ipairs(PRIZE_LIST) do
  if not prize.id then
    prize.id = prize.name
  end

  PRIZE_MAP[prize.id] = prize

  Net.register_item(prize.id, {
    name = prize.name,
    description = "A prize counter novelty.",
    consumable = true
  })
end

return {
  ---@type Arcade.PrizeData[]
  LIST = PRIZE_LIST,
  ---@type table<string, Arcade.PrizeData>
  MAP = PRIZE_MAP
}
