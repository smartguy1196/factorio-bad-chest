
--### JOIN.JS BUILT THIS LUA FILE ###
--This script was created from lua files in .\controls using the 'join.js' in nodejs (in POWERSHELL, run: node join.js)

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--table_deep_copy.lua
--FILEPATH:
--.\controls\1 (header) - 1 (library) - 1 - table_deep_copy.lua

--Deep Copy Function
local function tdc(object)
	-- Deep-copy of lua table, from factorio util.lua
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= 'table' then return object
			elseif object.__self then return object
			elseif lookup_table[object] then return lookup_table[object] end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object)
			do new_table[_copy(index)] = _copy(value) end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--getter_functions.lua
--FILEPATH:
--.\controls\1 (header) - 1 (library) - 2 - getter_functions.lua

function get_area( deployer )
  local X = get_signal( deployer, X_SIGNAL )
  local Y = get_signal( deployer, Y_SIGNAL )
  local W = get_signal( deployer, WIDTH_SIGNAL )
  local H = get_signal( deployer, HEIGHT_SIGNAL )

  if W < 1 then W = 1 end
  if H < 1 then H = 1 end

  if settings.global["recursive-blueprints-area"].value == "corner" then
    -- Convert from top left corner to center
    X = X + math.floor((W - 1) / 2)
    Y = Y + math.floor((H - 1) / 2)
  end

  -- Align to grid
  if W % 2 == 0 then X = X + 0.5 end
  if H % 2 == 0 then Y = Y + 0.5 end

  -- Subtract 1 pixel from edges to avoid tile overlap
  W = W - 1/128
  H = H - 1/128

  return {
    {deployer.position.x+X-(W/2), deployer.position.y+Y-(H/2)},
    {deployer.position.x+X+(W/2), deployer.position.y+Y+(H/2)},
  }
end

-- Return integer value for given Signal: {type=, name=}
function get_signal( entity, signal )
  -- Cache the circuit networks to speed up performance
  local cache = global.net_cache[entity.unit_number]
  if not cache then
    cache = {last_update = -1}
    global.net_cache[entity.unit_number] = cache
  end
  -- Try to reload empty networks once per tick
  -- Never reload valid networks
  if cache.last_update < game.tick then
    if not cache.red_network or not cache.red_network.valid then
      cache.red_network = entity.get_circuit_network(defines.wire_type.red)
    end
    if not cache.green_network or not cache.green_network.valid then
      cache.green_network = entity.get_circuit_network(defines.wire_type.green)
    end
    cache.last_update = game.tick
  end

  -- Get the signal
  local value = 0
  if cache.red_network then
    value = value + cache.red_network.get_signal(signal)
  end
  if cache.green_network then
    value = value + cache.green_network.get_signal(signal)
  end

  -- Mimic circuit network integer overflow
  if value > 2147483647 then value = value - 4294967296 end
  if value < -2147483648 then value = value + 4294967296 end
  return value
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--command_signals.lua
--FILEPATH:
--.\controls\1 (header) - 2 - command_signals.lua

-- Command signals
local DEPLOY_SIGNAL = {name="construction-robot", type="item"}
local DECONSTRUCT_SIGNAL = {name="deconstruction-planner", type="item"}
local COPY_SIGNAL = {name="signal-C", type="virtual"}
local X_SIGNAL = {name="signal-X", type="virtual"}
local Y_SIGNAL = {name="signal-Y", type="virtual"}
local WIDTH_SIGNAL = {name="signal-W", type="virtual"}
local HEIGHT_SIGNAL = {name="signal-H", type="virtual"}
local ROTATE_SIGNAL = {name="signal-R", type="virtual"}

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--game_events.lua
--FILEPATH:
--.\controls\2 (event handlers) - 1 - game_events.lua

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

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--entity_events.lua
--FILEPATH:
--.\controls\2 (event handlers) - 2 - entity_events.lua

function on_built( event )
  local entity = event.created_entity or event.entity or event.destination
  if not entity or not entity.valid then return end
  if entity.name == "blueprint-deployer" then

    local uid = entity.unit_number
    global.recursive.deployers[ uid ] = entity
    global.recursive.chests[ uid ] = entity

  end
  if entity.name == "blueprint-combinator" then
    local uid = entity.unit_number
    global.recursive.deployers[ uid ] = entity
    build_combinator( uid )

  end
end

local function on_entity_settings_pasted( event )
	if not ( ( event.source.name == 'blueprint-combinator' or event.source.name == 'blueprint-deployer' ) and ( event.destination.name == 'blueprint-combinator' or event.destination.name == 'blueprint-deployer' ) ) then return end
  local uid_source, uid_destination = event.source.unit_number, event.destination.unit_number

  local old_deployer = global.recursive.deployers[ uid_destination ]
  local inventory = {
    source = global.recursive.chests[ uid_source ].get_inventory( defines.inventory.chest ),
    destination = global.recursive.chests[ uid_destination ].get_inventory( defines.inventory.chest )
  }

  inventory.destination[ 1 ].set_stack( inventory.source[ 1 ] )
  global.recursive.deployers[ uid_destination ] = event.destination
  global.recursive.deploy_cache[ uid_destination ] = 0 + global.recursive.deploy_cache[ uid_source ]
  global.recursive.to_be_mined[ uid_destination ] = nil
  set_blueprint( uid_destination )


end

--todo: add on_mined and on_destroyed events

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--on_tick_deployer.lua
--FILEPATH:
--.\controls\3 (tick handling) - 1 - on_tick_deployer.lua

function on_tick_deployer( uid )

  local deployer = global.recursive.deployers[ uid ]

  --this rebuilds deployer if a part is removed/broken

  if deployer.name == "deployer-combinator" then
    if not ( global.recursive.chests[ uid ] and global.recursive.outputs[ uid ] ) then
      build_combinator( uid )
    end
  elseif not global.recursive.chests[ uid ] then
    global.recursive.chests[ uid ] = deployer
  end
  local chest = global.recursive.chests[ uid ]
  local output = global.recursive.outputs[ uid ]
  local deploy_cache = global.recursive.deploy_cache[ uid ]

  local deploy = get_signal( deployer, DEPLOY_SIGNAL )
  if deploy_cache ~= deploy then
    global.recursive.deploy_cache[ uid ] = 0 + deploy
    set_blueprint( uid )
  end

  local blueprint = global.recursive.blueprints[ uid ]

  if deploy > 0 then
    if blueprint.is_blueprint then
      -- Deploy blueprint
      deploy_blueprint( uid )
    elseif blueprint.is_deconstruction_item then
      -- Deconstruct area
      deconstruct_area( uid, true )
    elseif blueprint.is_upgrade_item then
      -- Upgrade area
      upgrade_area( blueprint, deployer, true )
    end
    return
  end

  if deploy == -1 then
    if blueprint.is_deconstruction_item then
      -- Cancel deconstruction in area
      deconstruct_area( uid, false )
    elseif blueprint.is_upgrade_item then
      -- Cancel upgrade in area
      upgrade_area( uid, false )
    end
    return
  end

  local deconstruct = get_signal( deployer, DECONSTRUCT_SIGNAL )
  if deconstruct == -1 then
    -- Deconstruct area
    deconstruct_area( uid, true )
    return
  elseif deconstruct == -2 then
    -- Deconstruct self
    deployer.order_deconstruction( deployer.force )
    return
  elseif deconstruct == -3 then
    -- Cancel deconstruction in area
    deconstruct_area( uid, false )
    return
  end

  local copy = get_signal( deployer, COPY_SIGNAL )
  if copy == 1 then
    -- Copy blueprint
    copy_blueprint( uid )
    return
  elseif copy == -1 then
    -- Delete blueprint
    local stack = chest.get_inventory( defines.inventory.chest )[1]
    if not stack.valid_for_read then return end
    if stack.is_blueprint
    or stack.is_blueprint_book
    or stack.is_upgrade_item
    or stack.is_deconstruction_item then
      stack.clear()
    end

    set_blueprint( uid )
    return
  end
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--deployer_remove.lua
--FILEPATH:
--.\controls\4 (handler helpers) - 1 - deployer_remove.lua

function deployer_remove( uid, keep_entities, to_be_mined )

	if not keep_entities then
		local deployer = global.recursive.deployers[ uid ]
		local output = global.recursive.outputs[ uid ]
		local chest = global.recursive.chests[ uid ]

		if chest and chest.valid and deployer and deployer.valid then
			if chest ~= deployer then
				chest.destroy()
			else
		    local stack = chest.get_inventory( defines.inventory.chest )[1]
		    if stack.valid_for_read then
			    if stack.is_blueprint
			    or stack.is_blueprint_book
			    or stack.is_upgrade_item
			    or stack.is_deconstruction_item then
			      stack.clear()
			    end
				end
			end
		end
		if output and output.valid then output.destroy() end
		if not to_be_mined and deployer and deployer.valid then
			deployer.destroy()
			global.recursive.to_be_mined[ uid ] = nil
		else
			global.recursive.to_be_mined[ uid ] = true
		end
	end
	global.recursive.deployers[ uid ] = nil
	global.recursive.chests[ uid ] = nil
	global.recursive.outputs[ uid ] = nil
	global.recursive.blueprints[ uid ] = nil
	global.recursive.deploy_cache[ uid ] = nil


end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--build_combinator.lua
--FILEPATH:
--.\controls\4 (handler helpers) - 2 - build_combinator.lua

function buid_combinator( uid )

  local deployer = global.recursive.deployers[ uid ]

  if not global.recursive.to_be_mined[ uid ] then
    if global.recursive.outputs[ uid ] then global.recursive.outputs.destroy() end
    if global.recursive.chests[ uid ] then global.recursive.chests.destroy() end
    local output = deployer.surface.created_entity{
      name = "blueprint-core-const",
      postion = deployer.position,
      force = deployer.force,
      create_build_effect_smoke = false
    }
    local chest = deployer.surface.created_entity{
      name = "blueprint-core-chest",
      postion = deployer.position,
      force = deployer.force,
      create_build_effect_smoke = false
    }
    deployer.connect_neighbor{
      wire = defines.wire_type.red, target_entity = output,
      source_circuit_id = defines.circuit_connector_id.combinator_output
    }
    deployer.connect_neighbor{
      wire = defines.wire_type.green, target_entity = output,
      soruce_circuit_id = defines.circuit_connector_id.combinator_output
    }
    global.recursive.outputs[ uid ] = output
    global.recursive.chests[ uid ] = chest`
  end
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--set_blueprint.lua
--FILEPATH:
--.\controls\5 (active bp control) - 1 - set_blueprint.lua

function set_blueprint( uid )

  local deployer = global.recursive.deployers[ uid ]
  local chest = global.recursive.chests[ uid ]
  global.recursive.blueprints[ uid ] = nil
  local blueprint = nil

  local deploy = global.recursive.deploy_cache[ uid ]

  if chest.get_inventory( defines.inventory.chest )[1] then

    blueprint = chest.get_inventory( defines.inventory.chest )[1]
    if not blueprint.valid_for_read then return end
    if blueprint.is_blueprint_book then

      local book_inventory = blueprint.get_inventory( defines.inventory.item_main )
      local size = inventory.get_item_count()
      if size < 1 then return end

      if deploy > size then deploy = blueprint.active_index end
      blueprint = book_inventory[ deploy ]
      if not blueprint.valid_for_read then return end

      global.recursive.blueprints[ uid ] = blueprint
    end
  end

  update_output( uid )

  return blueprint
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--update_output.lua
--FILEPATH:
--.\controls\5 (active bp control) - 2 - update_output.lua

local function map_signals( map )
    local signals = {}
    local i = 1
    for k, v in pairs(map) do
        signals[i] = {
            count = v,
            index = i,
            signal = { name = k, type = "item" }
        }
        i = i + 1
    end
    return signals
end

function update_output( uid )
  if not global.recursive.deployers[ uid ].name == "blueprint-combinator" then return end

  local blueprint = global.recursive.blueprints[ uid ]
  if not blueprint.is_blueprint_setup() then return end

  local output = global.recursive.outputs[ uid ]
  local control = {
    output = output.get_or_create_control_behavior()
  }

  local entities = blueprint.get_blueprint_entities()
  local tiles = blueprint.get_blueprint_tiles()

  local map = {}

  local count = {
    entities = 0,
    tiles = 0,
    map = 0
  }

  if entities then
    for _, entity in pairs( entities ) do
      count.entities = count.entities + 1
      local item = game.entity_prototypes[ entity.name ].items_to_place_this[ 1 ]
      if type( item ) == "string" then
        item = {
          name = item,
          count = game.item_prototypes[ item ].stack_size
        }
      end

      map[ item.name ] = ( map[ item.name ] or 0 ) + item.count
    end
  end

  if tiles then
    for _, tile in pairs( tiles ) do
      count.tiles = count.tiles + 1
      local item = game.entity_prototypes[ tiles.name ].items_to_place_this[ 1 ]
      if type( item ) == "string" then
        item = {
          name = item,
          count = game.item_prototypes[ item ].stack_size
        }
      end

      map[ item.name ] = ( map[ item.name ] or 0 ) + item.count
    end
  end

  for _ in pairs( map ) do count.map = count.map + 1 end

  signals = map_signals( map )
  control.output.enabled, control.output.parameters = true, { parameters = signals }

end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--deploy_blueprint.lua
--FILEPATH:
--.\controls\6 (deployer actions) - 1 - deploy_blueprint.lua

function deploy_blueprint( uid )

  local deployer = global.recursive.deployers[ uid ]
  local blueprint = global.recursive.blueprints[ uid ]

  if not blueprint then return end
  if not blueprint.valid_for_read then return end
  if not blueprint.is_blueprint_setup() then return end

  -- Rotate
  local rotation = get_signal( deployer, ROTATE_SIGNAL )
  local direction = defines.direction.north
  if (rotation == 1) then
    direction = defines.direction.east
  elseif (rotation == 2) then
    direction = defines.direction.south
  elseif (rotation == 3) then
    direction = defines.direction.west
  end

  -- Shift x,y coordinates
  local position = {
    x = deployer.position.x + get_signal( deployer, X_SIGNAL ),
    y = deployer.position.y + get_signal( deployer, Y_SIGNAL ),
  }

  -- Check for building out of bounds
  if position.x > 1000000
  or position.x < -1000000
  or position.y > 1000000
  or position.y < -1000000 then
    return
  end

  local result = blueprint.build_blueprint{
    surface = deployer.surface,
    force = deployer.force,
    position = position,
    direction = direction,
    force_build = true,
  }

  for _, entity in pairs(result) do
    script.raise_event(defines.events.script_raised_built, {
      entity = entity,
      stack = blueprint,
    })
  end
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--deconstruct_+_upgrade_area.lua
--FILEPATH:
--.\controls\6 (deployer actions) - 2 - deconstruct_+_upgrade_area.lua

function deconstruct_area( uid, deconstruct )
  local deployer = global.recursive.deployers[ uid ]
  local blueprint = global.recursive.blueprints[ uid ]

  local area = get_area( deployer )
  if deconstruct == false then
    -- Cancel area
    deployer.surface.cancel_deconstruct_area{
      area = area,
      force = deployer.force,
      skip_fog_of_war = false,
      item = bp,
    }
  else
    -- Deconstruct area
    local deconstruct_self = deployer.to_be_deconstructed( deployer.force )
    deployer.surface.deconstruct_area{
      area = area,
      force = deployer.force,
      skip_fog_of_war = false,
      item = bp,
    }
    if not deconstruct_self then
       -- Don't deconstruct myself in an area order
      deployer.cancel_deconstruction( deployer.force )
    end
  end
end

function upgrade_area( uid, upgrade )

  local deployer = global.recursive.deployers[ uid ]
  local blueprint = global.recursive.blueprints[ uid ]

  local area = get_area( deployer )
  if upgrade == false then
    -- Cancel area
    deployer.surface.cancel_upgrade_area{
      area = area,
      force = deployer.force,
      skip_fog_of_war = false,
      item = blueprint,
    }
  else
    -- Upgrade area
    deployer.surface.upgrade_area{
      area = area,
      force = deployer.force,
      skip_fog_of_war = false,
      item = blueprint,
    }
  end
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--copy_blueprint.lua
--FILEPATH:
--.\controls\6 (deployer actions) - 3 - copy_blueprint.lua

function copy_blueprint( uid )

  local deployer = global.recursive.deployers[ uid ]
  local chest = global.recursive.chests[ uid ]

  local inventory = chest.get_inventory( defines.inventory.chest )
  if not inventory.is_empty() then return end
  for _, signal in pairs( global.blueprint_signals ) do
    -- Check for a signal before doing an expensive search
    if get_signal( deployer, signal ) >= 1 then
      -- Signal exists, now we have to search for the blueprint
      local stack = find_stack_in_network( deployer, signal.name )
      if stack then
        inventory[1].set_stack( stack )
        set_blueprint( uid )
        return
      end
    end
  end
end

function con_hash( entity, connector, wire )
  return entity.unit_number .. "-" .. connector .. "-" .. wire
end

-- Breadth-first search for an item in the circuit network
-- If there are multiple items, returns the closest one (least wire hops)
function find_stack_in_network( deployer, item_name )
  local conn_id = nil
  if deployer.name == "blueprint-combinator" then
    conn_id = defines.circuit_connector_id.combinator_input
  else
    conn_id = defines.circuit_connector_id.container
  end
  local present = {
    [con_hash(deployer, conn_id, defines.wire_type.red)] =
    {
      entity = deployer,
      connector = conn_id,
      wire = defines.wire_type.red,
    },
    [con_hash(deployer, conn_id, defines.wire_type.green)] =
    {
      entity = deployer,
      connector = conn_id,
      wire = defines.wire_type.green,
    }
  }
  local past = {}
  local future = {}
  while next(present) do
    for key, con in pairs(present) do
      -- Search connecting wires
      for _, def in pairs(con.entity.circuit_connection_definitions) do
        -- Wire color and connection points must match
        if def.target_entity.unit_number
        and def.wire == con.wire
        and def.source_circuit_id == con.connector then
          local hash = con_hash(def.target_entity, def.target_circuit_id, def.wire)
          if not past[hash] and not present[hash] and not future[hash] then
            -- Search inside the entity
            local stack = find_stack_in_container(def.target_entity, item_name)
            if stack then return stack end

            -- Add entity connections to future searches
            future[hash] = {
              entity = def.target_entity,
              connector = def.target_circuit_id,
              wire = def.wire
            }
          end
        end
      end
      past[key] = true
    end
    present = future
    future = {}
  end
end

function find_stack_in_container( entity, item_name )
  if entity.type == "container" or entity.type == "logistic-container" then
    local inventory = entity.get_inventory(defines.inventory.chest)
    for i = 1, #inventory do
      if inventory[i].valid_for_read and inventory[i].name == item_name then
        return inventory[i]
      end
    end
  elseif entity.type == "inserter" then
    local behavior = entity.get_control_behavior()
    if not behavior then return end
    if not behavior.circuit_read_hand_contents then return end
    if entity.held_stack.valid_for_read and entity.held_stack.name == item_name then
      return entity.held_stack
    end
  end
end

--------------------[JOIN.JS PART]---------------------
--PARTNAME:
--all_events.lua
--FILEPATH:
--.\controls\7 (event triggers) - all_events.lua

-- Global events
script.on_init(on_init)
script.on_configuration_changed(on_mods_changed)
script.on_event(defines.events.on_tick, on_tick)

-- Deployer events
local filter = {{filter = "name", name = "blueprint-deployer"},{filter = "name", name = "blueprint-combinator"}}
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)

script.on_event(defines.events.on_pre_player_mined_item, on_mined, filter)
script.on_event(defines.events.on_robot_pre_mined, on_mined, filter)
script.on_event(defines.events.on_entity_died, on_destroyed, filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, filter)

script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

--todo: control combinator LEDs


-----------------------[TODOS:]------------------------
-------------------------------------------------------
--[ENTITY_EVENTS.LUA] (from part 2-2):
--## add on_mined and on_destroyed events

-------------------------------------------------------
--[ALL_EVENTS.LUA] (from part 7):
--## control combinator LEDs
