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
