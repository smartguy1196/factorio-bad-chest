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
