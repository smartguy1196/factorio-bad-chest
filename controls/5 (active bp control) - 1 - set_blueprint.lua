function set_blueprint( uid )

  local deployer = global.recursive.deployers[ uid ]
  local chest = global.recursive.chests[ uid ]
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

--todo: update output combinator

  return blueprint
end
