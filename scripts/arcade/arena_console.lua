local CONSOLE_COLOR = { 15, 120, 39 }

local TFC_CHAIN_LIMIT_OPTIONS = {
  "None",
  "1/Plyr",
  "1/Team",
}

---@param list any[]
local function pick_next(list, value)
  local current_i

  for i, v in ipairs(list) do
    if v == value then
      current_i = i
      break
    end
  end

  if current_i then
    local next_value = list[current_i + 1]

    if next_value then
      return next_value
    end
  end

  return list[1]
end

local function prompt_range(player_id, min, max, callback)
  local char_limit = math.log(max, 10) + 1

  if min < 0 then
    char_limit = char_limit + 1
  end

  Async.prompt_player(player_id, char_limit).and_then(function(value)
    value = tonumber(value)

    if not value then return end

    value = math.min(max, math.max(min, value))

    callback(value)
  end)
end

---@class Arcade._BattleConfigOptionProperties
---@field id string
---@field default any
---@field constructor (fun(value): string, any)
---@field on_select fun(player_id: Net.ActorId, prev_value, callback: fun(value))

---@type Arcade._BattleConfigOptionProperties[]
local config_options = {
  {
    id = "tfc_limit",
    default = "None",
    constructor = function(value)
      return "TFC Limit", value
    end,
    on_select = function(_, prev_value, callback)
      callback(pick_next(TFC_CHAIN_LIMIT_OPTIONS, prev_value))
    end
  },
  {
    id = "turn_limit",
    default = 15,
    constructor = function(value)
      return "Turn Limit", value
    end,
    on_select = function(player_id, _, callback)
      prompt_range(player_id, 1, 1000, callback)
    end
  },
  {
    id = "select_time",
    default = 120,
    constructor = function(value)
      return "Select Time", value .. "s"
    end,
    on_select = function(player_id, _, callback)
      prompt_range(player_id, 0, 10000, callback)
    end
  },
  {
    id = "randomize",
    default = true,
    constructor = function(value)
      return "Randomize", value and "Yes" or "No"
    end,
    on_select = function(_, prev_value, callback)
      callback(not prev_value)
    end
  },
  {
    id = "field_width",
    default = 6,
    constructor = function(value)
      return "Field Width", value
    end,
    on_select = function(player_id, _, callback)
      -- smaller than 255 to account for edge tile padding, and to round to a nice number
      prompt_range(player_id, 2, 250, function(value) callback(value + value % 2) end)
    end
  },
  {
    id = "field_height",
    default = 3,
    constructor = function(value)
      return "Field Height", value
    end,
    on_select = function(player_id, _, callback)
      -- smaller than 255 to account for edge tile padding, and to round to a nice number
      prompt_range(player_id, 1, 250, callback)
    end
  },
  {
    id = "damage_multiplier",
    default = 1,
    constructor = function(value)
      return "Damage", value .. "x"
    end,
    on_select = function(player_id, _, callback)
      prompt_range(player_id, -100, 100, callback)
    end
  },
}

---@type table<string, Arcade._BattleConfigOptionProperties>
local config_option_map = {}

for _, option in ipairs(config_options) do
  config_option_map[option.id] = option
end

local function create_post(custom_config, field_id)
  local option = config_option_map[field_id]
  local value = custom_config[field_id]
  local title, display_value = option.constructor(value)
  return { read = value == option.default, id = field_id, title = title, author = tostring(display_value) }
end

---@param arena BattleArena
---@param console_object_id number
local function tie_console(arena, console_object_id)
  local config_viewers = {}
  local custom_config = {}
  for _, option in ipairs(config_options) do
    custom_config[option.id] = option.default
  end

  local arena_events = arena:events()

  arena_events:on("preparing_battle", function(event)
    event.data.custom_config = custom_config
  end)

  local interaction_listener = function(interaction_event)
    local player_id = interaction_event.player_id

    if
        interaction_event.object_id ~= console_object_id or
        Net.get_actor_area(player_id) ~= arena.area_id
    then
      return
    end

    -- build and display a board
    Async.create_scope(function()
      ---@type Net.BoardPost[]
      local posts = {}

      for i, option in ipairs(config_options) do
        posts[i] = create_post(custom_config, option.id)
      end

      local events = Net.open_board(player_id, "Battle Options", CONSOLE_COLOR, posts)
      config_viewers[player_id] = true

      for post_event in Async.await(events:async_iter("post_selection")) do
        local field_id = post_event.post_id
        local option = config_option_map[field_id]
        local prev_value = custom_config[field_id]

        -- handle interaction
        option.on_select(player_id, prev_value, function(value)
          custom_config[field_id] = value

          -- update for all viewers
          Net.synchronize(function()
            local new_posts = { create_post(custom_config, field_id) }

            for viewer_id in pairs(config_viewers) do
              Net.append_posts(viewer_id, new_posts, field_id)
              Net.remove_post(viewer_id, field_id)
            end
          end)
        end)
      end

      config_viewers[player_id] = false
    end)
  end

  Net:on("object_interaction", interaction_listener)

  arena_events:on("destroyed", function()
    Net:remove_listener("object_interaction", interaction_listener)
  end)
end

return tie_console
