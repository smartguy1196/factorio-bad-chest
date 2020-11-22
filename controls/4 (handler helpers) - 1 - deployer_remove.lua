function deployer_remove( uid, keep_entities, to_be_mined )

  --todo: add code to delete deployer fully on destruction of deployer entity
  --global.recursive.deployers[ uid ] = nil
  --global.recursive.chests[ uid ] = nil
  --global.recursive.outputs[ uid ] = nil
  --global.recursive.blueprints[ uid ] = nil
	if not keep_entities then
		local deployer = global.recursive.deployers[ uid ]
    local output = global.recursive.outputs[ uid ]
    local chest = global.recursive.chests[ uid ]

    if chest and chest.valid and deployer and deployer.valid and chest ~= deployer then chest.destroy() end
    if output and output.valid then output.destroy() end
		if not to_be_mined and deployer and deployer.valid then deployer.destroy() end
	end
	global.recursive.deployers[ uid ] = nil
	global.recursive.chests[ uid ] = nil
	global.recursive.outputs[ uid ] = nil
	global.recursive.blueprints[ uid ] = nil
	global.recursive.deploy_cache[ uid ] = nil


end
