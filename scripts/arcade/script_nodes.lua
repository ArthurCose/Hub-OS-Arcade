local ScriptNodes = require("scripts/libs/script_nodes")

local scripts = ScriptNodes:new()

for _, area_id in ipairs(Net.list_areas()) do
  scripts:load(area_id)
end

-- copied from script nodes
local function transfer_to_area(context, object, area_id)
  local x, y, z
  local warp_in
  local direction

  warp_in, x, y, z, direction = scripts:resolve_teleport_properties(object, area_id)

  if not x then
    x, y, z = Net.get_spawn_position_multi(area_id)
  end

  if not direction then
    direction = Net.get_spawn_direction(area_id)
  end

  if context.player_ids then
    for _, player_id in ipairs(context.player_ids) do
      Net.transfer_actor(player_id, area_id, warp_in, x, y, z, direction)
    end
  else
    Net.transfer_actor(context.player_id, area_id, warp_in, x, y, z, direction)
  end
end

local code_to_area = {}
local area_to_code = {}

scripts:instancer():events():on("area_removed", function(event)
  local code = area_to_code[event.area_id]

  if code then
    code_to_area[code] = nil
    area_to_code[event.area_id] = nil
  end
end)


scripts:implement_node("coded instance", function(context, object)
  if context.player_ids then
    error("the Coded Instance node does not support parties")
  end

  Async.create_scope(function()
    local code = Async.await(Async.prompt_player(context.player_id))

    if not code then
      -- disconnected
      return
    end

    if code == "" then
      scripts:execute_next_node(context, context.area_id, object)
      return
    end

    local instanced_area_id = code_to_area[code]

    if not instanced_area_id then
      local instancer = scripts:instancer()
      local instance_id = instancer:create_instance({ auto_remove = true })
      instanced_area_id = instancer:clone_area_to_instance(instance_id, object.custom_properties.Area) --[[@as string]]
      code_to_area[code] = instanced_area_id
      area_to_code[instanced_area_id] = code
    end

    transfer_to_area(context, object, instanced_area_id)
    scripts:execute_next_node(context, context.area_id, object)
  end)
end)

return scripts
