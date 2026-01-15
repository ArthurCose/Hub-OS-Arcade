local bug_pool = {
  "BattleNetwork4.Bugs.ForwardMovement",
  "BattleNetwork4.Bugs.BackwardMovement",
  "BattleNetwork6.Bugs.BattleHPBug",
  "BattleNetwork6.Bugs.BusterBug",
  "BattleNetwork6.Bugs.EmotionBug",
  "BattleNetwork6.Bugs.PanelBug",
  "BattleNetwork6.Bugs.WarpStep",
}

---@param status Status
function status_init(status)
  local owner = status:owner()

  local bug = bug_pool[math.random(#bug_pool)]

  owner:boost_augment(bug, 1)

  if bug == "BattleNetwork6.Bugs.BusterBug" and not owner:get_augment("BattleNetwork6.Bugs.BusterJam") then
    -- re-enable buster jam >:)
    owner:boost_augment("BattleNetwork6.Bugs.BusterJam", 1)
  end
end
