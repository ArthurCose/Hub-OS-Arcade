local create_dark_meteor = require("meteor")
local create_fist = require("fist")

local Lib = {}

local element_weakness_map = {
  [Element.Fire] = Element.Aqua,
  [Element.Aqua] = Element.Elec,
  [Element.Elec] = Element.Wood,
  [Element.Wood] = Element.Fire,
  [Element.Sword] = Element.Break,
  [Element.Cursor] = Element.Wind,
  [Element.Wind] = Element.Sword,
  [Element.Break] = Element.Cursor
}

local function try_spawn_bug_frag(owner)
  local tiles = Field.find_tiles(function(tile)
    return tile:is_walkable() and not tile:is_reserved()
  end)

  local spawn_tile = tiles[math.random(#tiles)]

  if not spawn_tile then
    return
  end

  local bug_frag = Obstacle.new(Team.Other)
  bug_frag:set_health(50)
  bug_frag:enable_hitbox(false)
  bug_frag:set_owner(owner)

  local sprite = bug_frag:sprite()
  sprite:set_texture("bug.png")

  local animation = bug_frag:animation()
  animation:load("bug.animation")
  animation:set_state("DEFAULT")
  animation:set_playback(Playback.Loop)

  bug_frag.can_move_to_func = function(tile)
    return tile:is_walkable() and not tile:is_reserved()
  end

  local delete = function()
    bug_frag:delete()
  end

  bug_frag:add_aux_prop(AuxProp.new():declare_immunity(~Hit.Drag))
  bug_frag:add_aux_prop(AuxProp.new():require_hit_element(Element.Break):with_callback(delete))
  bug_frag:add_aux_prop(AuxProp.new():require_hit_flags(Hit.PierceGuard):with_callback(delete))

  local i = 0
  bug_frag.on_update_func = function()
    i = i + 1

    bug_frag:current_tile():remove_reservation_for(bug_frag)

    if i < 30 then
      sprite:set_visible(i // 2 % 2 == 0)
      return
    end

    sprite:set_visible(true)
    bug_frag:enable_hitbox(true)

    if i > 5 * 60 then
      bug_frag:delete()
      return
    end

    local tile = bug_frag:current_tile()

    tile:find_players(function(player)
      local card = CardProperties.from_package("BattleNetwork6.Class01.Standard.177")
      local action = Action.from_card(player, card)

      if action then
        player:queue_action(action)
      end

      player:apply_status(Hit.ArcadeBug, 1)

      bug_frag:erase()
      return false
    end)
  end

  bug_frag.on_delete_func = function()
    animation:set_state("DESPAWN")
    animation:on_complete(function()
      bug_frag:erase()
    end)
  end

  Field.spawn(bug_frag, spawn_tile)
end

function Lib.init()
  local artifact = Artifact.new(Team.Other)

  local original_element_map = {}

  artifact:create_component(Lifetime.Scene).on_update_func = function(self)
    self:eject()

    -- resolve original elements for resolving if a player is using a form
    Field.find_players(function(player)
      original_element_map[player:id()] = player:element()
      return false
    end)

    -- smite players using healing chips
    Field.find_players(function(player)
      player:add_aux_prop(
        AuxProp.new()
        :require_card_recover(Compare.GT, 0)
        :intercept_action(function(action)
          local hit_props = HitProps.new(
            500,
            Hit.PierceGuard | Hit.PierceInvis | Hit.Flinch | Hit.Flash | Hit.ArcadeBug,
            Element.Break,
            Element.Cursor
          )

          local explosion_hit_props = HitProps.new(
            200,
            Hit.Flinch | Hit.Flash | Hit.ArcadeBug,
            Element.None
          )

          local fist = create_fist(Team.Other, player:facing_away(), hit_props, explosion_hit_props)

          Field.spawn(fist, player:current_tile())

          return action
        end)
      )

      return false
    end)
  end

  local meteors_spawned = 0
  local decross_cooldown = 0
  local bug_frag_cooldown = math.random(60 * 4, 60 * 12)

  artifact:create_component(Lifetime.ActiveBattle).on_update_func = function()
    -- punish crossed players with meteors
    if decross_cooldown > 0 then
      decross_cooldown = decross_cooldown - 1
    else
      local crossed_players = Field.find_players(function(player)
        return player:element() ~= original_element_map[player:id()]
      end)

      if #crossed_players > 0 then
        local target = crossed_players[math.random(#crossed_players)]

        local hit_props = HitProps.new(
          100,
          Hit.Flinch | Hit.Flash | Hit.ArcadeBug,
          element_weakness_map[target:element()] or Element.None
        )

        Field.spawn(
          create_dark_meteor(Team.Other, target:facing_away(), hit_props),
          target:current_tile()
        )

        meteors_spawned = meteors_spawned + 1

        if meteors_spawned == 3 then
          decross_cooldown = 60 * 5
          meteors_spawned = 0
        else
          decross_cooldown = 30
        end
      end
    end

    -- spawn buster up bugfrag
    if bug_frag_cooldown > 0 then
      bug_frag_cooldown = bug_frag_cooldown - 1
    else
      bug_frag_cooldown = math.random(60 * 10, 60 * 20)

      try_spawn_bug_frag(artifact)
    end
  end

  artifact.on_battle_end_func = function()
    artifact:delete()
  end

  Field.spawn(artifact, 0, 0)
end

return Lib
