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
