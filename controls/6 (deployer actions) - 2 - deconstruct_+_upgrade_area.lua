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
