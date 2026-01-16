local PlayerSaveData = require("scripts/arcade/player_data")
local Prizes = require("scripts/arcade/prize_data")
local HashedList = require("scripts/arcade/hashed_list")

local PRIZE_TEXTURE_PATH = "/server/assets/bots/prizes.png"
local PRIZE_ANIM_PATH = "/server/assets/bots/prizes.animation"

---@param prize Arcade.PrizeData
function prize_preview_anim_path(prize)
  return "/server/assets/prize_previews/" .. prize.state .. ".animation"
end

-- the server runs at 20 ticks per second
local PRIZE_DISPLAY_COOLDOWN = 15

---@class Arcade.PlayerSessionData
---@field id Net.ActorId
---@field prize_display_cooldown number
---@field prize_bot Net.ActorId?
---@field viewing_prize_counter? boolean
---@field direction string

---@type Arcade.HashedList<Net.ActorId, Arcade.PlayerSessionData>
local players = HashedList:new()

---@param data Arcade.PlayerSessionData
local function despawn_prize_bot(data)
  if data.prize_bot then
    Net.remove_bot(data.prize_bot, false)
    data.prize_bot = nil
  end
end

---@param id Net.ActorId
local function test_facing_right(id)
  local direction = Net.get_player_direction(id)
  return direction and direction:sub(-4) ~= "LEFT"
end

local PRIZE_OFFSETS = {
  ["UP"]         = { 0.25, -0.3 },
  ["DOWN"]       = { 0.25, -0.3 },

  ["LEFT"]       = { 0.5, -0.1 },
  ["RIGHT"]      = { -0.1, 0.5 },

  ["DOWN LEFT"]  = { 0.5, -0.1 },
  ["UP LEFT"]    = { 0.0, 0.25 },

  ["UP RIGHT"]   = { 0.5, -0.1 },
  ["DOWN RIGHT"] = { -0.1, 0.5 },
}

---@param data Arcade.PlayerSessionData
---@param save_data Arcade.PlayerSaveData
local function update_prize_bot(data, save_data)
  if not data.prize_bot or not save_data.active_prize then
    return
  end

  local prize = Prizes.MAP[save_data.active_prize]

  if not prize then
    return
  end

  local state = prize.state

  if not test_facing_right(data.id) then
    state = state .. "_MIRRORED"
  end

  Net.animate_bot(data.prize_bot, state, true)
end

---@param data Arcade.PlayerSessionData
local function spawn_prize_bot(data)
  despawn_prize_bot(data)

  local x, y, z = Net.get_player_position_multi(data.id)
  local offset = PRIZE_OFFSETS[data.direction]

  data.prize_bot = Net.create_bot({
    area_id = Net.get_player_area(data.id),
    warp_in = false,
    texture_path = PRIZE_TEXTURE_PATH,
    animation_path = PRIZE_ANIM_PATH,
    animation = "DEFAULT",
    x = x + offset[1],
    y = y + offset[2],
    z = z,
    solid = false,
  })

  PlayerSaveData.fetch(data.id).and_then(function(save_data)
    update_prize_bot(data, save_data)
  end)
end

Net:on("player_move", function(event)
  local data = players:get(event.player_id)

  if data then
    despawn_prize_bot(data)
    data.prize_display_cooldown = PRIZE_DISPLAY_COOLDOWN
  end
end)

Net:on("player_join", function(event)
  players:insert(event.player_id, {
    id = event.player_id,
    prize_display_cooldown = PRIZE_DISPLAY_COOLDOWN,
    direction = Net.get_player_direction(event.player_id)
  })
end)

Net:on("player_disconnect", function(event)
  local data = players:swap_remove(event.player_id, function(data) return data.id end)

  if data then
    despawn_prize_bot(data)
  end
end)

Net:on("tick", function(event)
  for _, data in ipairs(players.list) do
    if data.prize_display_cooldown > 0 then
      -- tick until we can spawn the prize bot
      data.prize_display_cooldown = data.prize_display_cooldown - 1

      if data.prize_display_cooldown == 0 then
        data.direction = Net.get_player_direction(data.id)
        spawn_prize_bot(data)
      end
    else
      -- see if we should rotate the prize bot
      local direction = Net.get_player_direction(data.id)

      if data.direction ~= direction then
        data.direction = direction

        PlayerSaveData.fetch(data.id).and_then(function(save_data)
          update_prize_bot(data, save_data)
        end)
      end
    end
  end
end)

local SHOP_MUG_TEXTURE = "/server/assets/bots/staff_mug.png"
local SHOP_MUG_ANIM_PATH = "/server/assets/bots/staff_mug.animation"

Net:on("object_interaction", function(event)
  local player_id = event.player_id
  local object = Net.get_object_by_id(Net.get_player_area(player_id), event.object_id)

  if object.name ~= "Prize Counter" then
    return
  end

  local data = players:get(player_id)

  if not data or data.viewing_prize_counter then
    return
  end

  data.viewing_prize_counter = true

  PlayerSaveData.fetch(player_id).and_then(function(save_data)
    local shop_items = {}

    for _, prize in ipairs(Prizes.LIST) do
      local item = {
        id = prize.id,
        name = prize.name,
        price = prize.price
      }

      local owned = save_data.inventory[prize.id]

      if owned and owned > 0 then
        item.price = 0
      end

      shop_items[#shop_items + 1] = item
    end

    local events = Net.open_shop(player_id, shop_items, SHOP_MUG_TEXTURE, SHOP_MUG_ANIM_PATH)

    Net.set_shop_message(player_id, "See anything you like?")

    events:on("shop_purchase", function(event)
      local prize = Prizes.MAP[event.item_id]

      if not prize then
        warn('Failed to find prize with id: "' .. event.item_id .. '"')
        return
      end

      local owned = save_data.inventory[prize.id]

      if owned and owned > 0 then
        Net.message_player(
          player_id,
          prize.name .. " misses you too!",
          SHOP_MUG_TEXTURE,
          SHOP_MUG_ANIM_PATH
        )

        save_data.active_prize = prize.id
        save_data:save(player_id)
        update_prize_bot(data, save_data)
        return
      end

      if save_data.money < prize.price then
        -- not enough money
        Net.message_player(
          player_id,
          "You'll need more tokens for " .. prize.name .. ".",
          SHOP_MUG_TEXTURE,
          SHOP_MUG_ANIM_PATH
        )
        return
      end

      Async.question_player(
        player_id, "Redeem " .. prize.name .. "?",
        PRIZE_TEXTURE_PATH,
        prize_preview_anim_path(prize)
      ).and_then(function(response)
        if response ~= 1 then
          return
        end

        save_data.money = save_data.money - prize.price
        save_data.inventory[prize.id] = 1
        save_data.active_prize = prize.id
        save_data:save(player_id)

        Net.give_player_item(player_id, prize.id)
        Net.set_player_money(player_id, save_data.money)
        update_prize_bot(data, save_data)

        Net.update_shop_item(player_id, {
          id = prize.id,
          name = prize.name,
          price = 0
        })

        Net.message_player(
          player_id,
          "Meet " .. prize.name .. ", congrats!",
          SHOP_MUG_TEXTURE,
          SHOP_MUG_ANIM_PATH
        )
      end)
    end)

    events:on("shop_description_request", function(event)
      local prize = Prizes.MAP[event.item_id]

      if not prize then
        warn('Failed to find prize with id: "' .. event.item_id .. '"')
        return
      end

      Net.message_player(
        player_id,
        "A prize counter novelty.",
        PRIZE_TEXTURE_PATH,
        prize_preview_anim_path(prize)
      )
    end)

    events:on("shop_leave", function()
      Net.set_shop_message(player_id, "Have fun!")
    end)

    events:on("shop_close", function()
      data.viewing_prize_counter = false
    end)
  end)
end)

Net:on("item_use", function(event)
  local data = players:get(event.player_id)

  if not data then
    return
  end

  if not Prizes.MAP[event.item_id] then
    return
  end

  PlayerSaveData.fetch(event.player_id).and_then(function(save_data)
    local mug = Net.get_player_mugshot(event.player_id)

    local prize = Prizes.MAP[event.item_id]

    if not prize then
      return
    end

    if save_data.active_prize == event.item_id then
      save_data.active_prize = nil
      save_data:save(event.player_id)

      despawn_prize_bot(data)

      Net.message_player(event.player_id, "Storing " .. prize.name .. ".", mug.texture_path, mug.animation_path)
      return
    end

    local owned = save_data.inventory[event.item_id]

    if not owned or owned == 0 then
      return
    end

    save_data.active_prize = event.item_id
    save_data:save(event.player_id)
    update_prize_bot(data, save_data)

    Net.message_player(event.player_id, "Holding " .. prize.name .. ".", mug.texture_path, mug.animation_path)
  end)
end)
