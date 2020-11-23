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

local function on_destroyed( event ) deployer_remove( event.entity.unit_number ) end
local function on_mined( event ) mlc_remove( event.entity.unit_number, nil, true ) end
