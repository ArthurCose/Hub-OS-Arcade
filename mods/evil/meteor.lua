local bn_assets = require("BattleNetwork.Assets")

local AUDIO = bn_assets.load_audio("meteor_land.ogg")

local TEXTURE = Resources.load_texture("meteor.png")
local ANIM_PATH = "meteor.animation"

local EXPLOSION_TEXTURE = bn_assets.load_texture("ring_explosion.png")
local EXPLOSION_ANIM_PATH = bn_assets.fetch_animation_path("ring_explosion.animation")

local function create_impact_explosion(tile, team)
  local explosion = Spell.new(team)
  explosion:set_texture(EXPLOSION_TEXTURE)

  local new_anim = explosion:animation()
  new_anim:load(EXPLOSION_ANIM_PATH)
  new_anim:set_state("DEFAULT")

  explosion:sprite():set_layer(-2)

  explosion.on_spawn_func = function()
    if tile:can_set_state(TileState.Broken) then tile:set_state(TileState.Broken) else tile:set_state(TileState.Cracked) end
    Field.shake(5, 18)
  end

  Field.spawn(explosion, tile)

  new_anim:on_complete(function()
    explosion:erase()
  end)
end

---@param team Team
---@param facing Direction
---@param hit_props HitProps
local function create_dark_meteor(team, facing, hit_props)
  local meteor = Spell.new(team)

  meteor:set_tile_highlight(Highlight.Flash)
  meteor:set_facing(facing)

  meteor:set_hit_props(hit_props)

  meteor:set_texture(TEXTURE)

  local anim = meteor:animation()
  anim:load(ANIM_PATH)
  anim:set_state("DEFAULT")
  meteor:sprite():set_layer(-2)

  local vel_x = 14
  local vel_y = 14

  if facing == Direction.Left then
    vel_x = -vel_x
  end

  meteor:set_offset(-vel_x * 8, -vel_y * 8)

  meteor.on_spawn_func = function()
    Resources.play_audio(AUDIO)
  end

  meteor.on_update_func = function(self)
    local offset = self:offset()
    if offset.y < 0 then
      self:set_offset(offset.x + vel_x, offset.y + vel_y)
      return
    end

    local tile = self:current_tile()

    if tile:is_walkable() then
      self:attack_tile()
      create_impact_explosion(tile, self:team())
    end

    self:erase()
  end

  return meteor
end

return create_dark_meteor
