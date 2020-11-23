if data.raw.technology["construction-robotics"]
and data.raw.technology["construction-robotics"].effects then
  -- Construction robotics unlocks deployer chest
  table.insert(
    data.raw.technology["construction-robotics"].effects,
    {type = "unlock-recipe", recipe = "blueprint-deployer"}
  )
  table.insert(
    data.raw.technology["construction-robotics"].effects,
    {type = "unlock-recipe", recipe = "blueprint-combinator"}
  )
else
  -- Unlock deployer chest from the start
  data.raw.recipe["blueprint-deployer"].enabled = true
  data.raw.recipe["blueprint-combinator"].enabled = true
end
