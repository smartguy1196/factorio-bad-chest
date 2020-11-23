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
