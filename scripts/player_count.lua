local player_count = 0

local function updated_player_count()
  local date = os.date("*t")
  local hour = string.format("%02d", date.hour)
  local min = string.format("%02d", date.min)

  print("[" .. hour .. ":" .. min .. "] player count: " .. player_count)
end

Net:on("player_request", function()
  player_count = player_count + 1
  updated_player_count()
end)

Net:on("player_disconnect", function()
  player_count = player_count - 1
  updated_player_count()
end)
