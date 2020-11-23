data:extend{
  {
    type = "recipe",
    name = "blueprint-deployer",
    result = "blueprint-deployer",
    enabled = false,
    ingredients = {
      {"steel-chest", 1},
      {"electronic-circuit", 3},
      {"advanced-circuit", 1},
    },
  },
  {
    type = "recipe",
    name = "blueprint-combinator"
    result = "blueprint-combinator"
    enabled = false,
    ingredients = {
      {"blueprint-deployer", 1},
      {"arithmetic-combinator", 1},
      {"advanced-circuit", 1},
    },
  },
}
