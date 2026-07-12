local TournamentIntro = require("BattleNetwork4.TournamentIntro")
---@type dev.konstinople.library.arcade_fields
local ArcadeFields = require("dev.konstinople.library.arcade_fields")

---@param encounter Encounter
function encounter_init(encounter, data)
  ArcadeFields.apply_pvp_rules(encounter)
  ArcadeFields.randomize_field()
  ArcadeFields.randomize_ambience(encounter)
  ArcadeFields.spawn_players(encounter, data)

  -- neon tournament intro
  local colors = {
    Color.new(255, 0, 255), -- magenta
    Color.new(0, 255, 255), -- cyan
    Color.new(255, 255, 0), -- yellow
    Color.new(0, 255, 0),   -- green
  }
  TournamentIntro.LINE_COLOR = colors[math.random(#colors)]
  TournamentIntro.init()


  -- the key part of defrost mats:
  local artifact = Artifact.new()

  ---@param entity Entity
  local function temporarily_disable_hitbox(entity)
    entity:enable_hitbox(false)

    local component = entity:create_component(Lifetime.Local)
    component.on_update_func = function()
      if not entity:has_actions() then
        entity:enable_hitbox(true)
        component:eject()
      end
    end
  end

  artifact.on_update_func = (function()
    artifact:delete()

    Field.find_characters(function(entity)
      entity:add_aux_prop(
        AuxProp.new()
        :require_card_time_freeze(true)
        :intercept_card(function(card_properties)
          temporarily_disable_hitbox(entity)

          card_properties.time_freeze = false

          return card_properties
        end)
      )

      entity:add_aux_prop(
        AuxProp.new()
        :require_card_time_freeze(true)
        :intercept_action(function(action)
          temporarily_disable_hitbox(entity)

          local card_properties = action:copy_card_properties()
          card_properties.time_freeze = false
          action:set_card_properties(card_properties)

          return action
        end)
      )

      return false
    end)
  end)

  Field.spawn(artifact, 0, 0)
end
