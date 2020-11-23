data:extend{
  {
    type = "item",
    name = "blueprint-deployer",
    icon = png("blueprint-deployer-icon"),
    icon_size = 32,
    subgroup = "logistic-network",
    order = "c[signal]-b[blueprint-deployer]",
    place_result = "blueprint-deployer",
    stack_size = 50,
  },
    {
      type = "item",
      name = "blueprint-combinator",
      icon = png("blueprint-combinator-icon"),
      icon_size = 32,
      subgroup = 'circuit-combinator' or 'circuit-network',
      order = "c[combinators]-bb[blueprint-combinator]",
      place_result = "blueprint-combinator",
      stack_size = 50,
    },
}
