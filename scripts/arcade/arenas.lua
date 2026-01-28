local BattleArenas = require("scripts/libs/battle_arenas")
local PlayerSaveData = require("scripts/arcade/player_data")

local LAUNCH_DIRS = { "Up", "Down" }
local area_id = "default"

for _, object_id in ipairs(Net.list_objects(area_id)) do
  local object = Net.get_object_by_id(area_id, object_id)

  if object.name == "Arena" then
    local x = object.x
    local y = object.y
    local w = object.width
    local h = object.height
    local z = object.z

    local team_ranges = {
      {
        team = "red",
        face_direction = "DOWN RIGHT",
        x = x,
        y = y,
        z = z,
        w = w / 2,
        h = h
      },
      {
        team = "blue",
        face_direction = "UP LEFT",
        x = x + w / 2,
        y = y,
        z = z,
        w = w / 2,
        h = h
      }
    }

    local launch_direction = object.custom_properties["Launch Direction"]
    local top = object.y
    local bottom = object.y + object.height
    local spectators_above = launch_direction ~= "Down"
    local spectators_below = launch_direction ~= "Up"

    if spectators_above then
      team_ranges[#team_ranges + 1] = {
        team = "spectators",
        face_direction = "DOWN LEFT",
        x = x,
        y = y - 1,
        z = z,
        w = w,
        h = 1
      }
    end

    if spectators_below then
      team_ranges[#team_ranges + 1] = {
        team = "spectators",
        face_direction = "UP RIGHT",
        x = x,
        y = bottom,
        z = z,
        w = w,
        h = 1
      }
    end

    local arena = BattleArenas.create_arena(area_id, {
      area_id = area_id,
      encounter_path = object.custom_properties.Encounter,
      pve = object.custom_properties.PVE == "true",
      min_players = (tonumber(object.custom_properties["Min Players"]) or 1),
      x = object.x,
      y = object.y,
      w = object.width,
      h = object.height,
      z = object.z,
      team_ranges = team_ranges,
      required_teams = { "red", "blue" }
    })

    arena.events:on("eject_player", function(event)
      if event.team_range.team == "spectators" then
        return
      end

      ---@type Net.ActorId
      local player_id = event.player_id
      ---@type number, number
      local x, z = event.x, event.z

      local personal_launch_dir = launch_direction or LAUNCH_DIRS[math.random(#LAUNCH_DIRS)]
      local target_y

      if personal_launch_dir == "Up" then
        target_y = top - math.random() * 0.5 - 0.3
      else
        target_y = bottom + math.random() * 0.5 + 0.3
      end

      local duration = 0.3

      Net.animate_player_properties(player_id, {
        {
          properties = {
            { property = "Direction", value = Net.get_player_direction(player_id) }
          }
        },
        {
          properties = {
            { property = "Z", value = z + 1, ease = "In" }
          },
          duration = duration * 0.75
        },
        {
          properties = {
            { property = "X", value = x,        ease = "Linear" },
            { property = "Y", value = target_y, ease = "Linear" },
            { property = "Z", value = z,        ease = "In" }
          },
          duration = duration
        }
      })
    end)

    local reward_min_turns = tonumber(object.custom_properties["Reward Min Turns"]) or 1
    local custom_bonus = object.custom_properties["Custom Bonus"] == "true"
    local custom_reward = object.custom_properties["Custom Reward"] == "true"

    if not custom_reward then
      arena.events:on("battle_results", function(event)
        if event.ran or event.turns <= reward_min_turns then
          return
        end

        local reward = 1

        if not custom_bonus and event.won then
          reward = reward + 1
        end

        PlayerSaveData.fetch(event.player_id).and_then(function(save_data)
          save_data.money = save_data.money + reward
          save_data:save(event.player_id)
          Net.set_player_money(event.player_id, save_data.money)
        end)
      end)
    end
  end
end

Net:on("battle_message", function(event)
  -- reward 1z for each defeated boss
  if type(event.data) ~= "table" then
    return
  end

  if event.data.type == "Defeated Boss" then
    if not event.data.alive then
      -- you can only receive zenny for defeating a multiman boss if you were alive for it
      return
    end
  elseif event.data.type ~= "Reached First Boss" then
    -- the only other signal we reward is reaching the first multiman boss
    return
  end

  PlayerSaveData.fetch(event.player_id).and_then(function(save_data)
    save_data.money = save_data.money + 1
    save_data:save(event.player_id)
    Net.set_player_money(event.player_id, save_data.money)
  end)
end)
