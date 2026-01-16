require("scripts/arcade/arenas")
require("scripts/arcade/prizes")

Net:on("player_connect", function(event)
  Net.set_player_restrictions(event.player_id, "/server/assets/restrictions.toml")
end)
