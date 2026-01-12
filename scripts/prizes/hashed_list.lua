---@class Arcade.HashedList<K, V>: {
---  map: table<`K`, number>,
---  list: `V`[],
---  insert: fun(self, key: `K`, value: `V`),
---  clear: fun(),
---  get: (fun(self, key: `K`): `V`),
---  swap_remove: (fun(self, key: `K`, callback: fun(swapped: `V`): `K`): `V`?),
---}

local HashedList = {}

---@generic K
---@generic V
---@return Arcade.HashedList<`K`, `V`>
function HashedList:new()
  local m = { map = {}, list = {} }
  setmetatable(m, self)
  self.__index = self
  return m
end

function HashedList:insert(key, value)
  local i = self.map[key] or (#self.list + 1)
  self.map[key] = i
  self.list[i] = value
end

function HashedList:get(key)
  local i = self.map[key]
  return i and self.list[i]
end

function HashedList:clear()
  for key, i in pairs(self.map) do
    self.list[i] = nil
    self.map[key] = nil
  end
end

function HashedList:swap_remove(key, callback)
  local i = self.map[key]

  if not i then
    return
  end

  local value = self.list[i]
  local swapped_value = self.list[#self.list]

  if swapped_value then
    self.map[callback(swapped_value)] = i
    self.list[i] = swapped_value
  end

  self.list[#self.list] = nil
  self.map[key] = nil

  return value
end

return HashedList
