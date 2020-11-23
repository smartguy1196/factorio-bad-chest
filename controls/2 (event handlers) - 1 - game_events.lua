local INITIAL_RECURSIVE = {
	deployers = {},
	chests = {},
	outputs = {},
	blueprints = {},
	deploy_cache = {},
	to_be_mined = {}
}

function on_init()
  --global.recursive = tdc( INITIAL_RECURSIVE )
	--not needed, because it is done in on_mods_changed()

  on_mods_changed()
end

function on_mods_changed()
  if not global.recursive then global.recursive = tdc( INITIAL_RECURSIVE ) end
  global.net_cache = {}

  -- Construction robotics unlocks deployer chest and combinator
  for _, force in pairs(game.forces) do
    if force.technologies["construction-robotics"].researched then
      force.recipes["blueprint-deployer"].enabled = true
      force.recipes["blueprint-combinator"].enabled = true
    end
  end

  -- Collect all modded blueprint signals in one table
  global.blueprint_signals = {}
  for _, item in pairs(game.item_prototypes) do
    if item.type == "blueprint"
    or item.type == "blueprint-book"
    or item.type == "upgrade-item"
    or item.type == "deconstruction-item" then
      table.insert( global.blueprint_signals, {name=item.name, type="item"} )
    end
  end
end

function on_tick( event )
  for uid, deployer in pairs( global.recursive.deployers ) do
    if deployer.valid then
      on_tick_deployer( uid )
    else
      deployer_remove( uid )
    end
  end
end
