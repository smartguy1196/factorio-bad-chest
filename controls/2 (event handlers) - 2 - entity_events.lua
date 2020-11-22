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
  deployer_remove( uid_destination, true )
  global.recursive.deployers[ uid_destination ] = event.destination
  if event.destination.name == "blueprint-combinator" then
    if event.source.name == "blueprint-combinator" then
      global.recursive.chests[ uid_destination ] = tdc( global.recursive.chests[ uid_source ] )
    else

      --todo:pass inventory from source deployer-chest to destination deployer-combinator

    end

    global.recursive.outputs[ uid_destination ] = tdc( global.recursive.outputs[ uid_source ] )
  else
    global.recursive.chests[ uid_destination ] = event.destination

    --todo:pass inventory from source to destination deployer-chest

  end
  global.recursive.deploy_cache[ uid_destination ] = 0 + global.recursive.deploy_cache[ uid_source ]
  set_blueprint( uid_destination )


end

--todo: add on_mined and on_destroyed events
